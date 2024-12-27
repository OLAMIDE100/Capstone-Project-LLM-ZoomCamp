import json
import pandas as pd
import minsearch
from openai import OpenAI
from template import prompt_template , entry_template , eval_template
import time
import os
from elasticsearch import Elasticsearch
from sentence_transformers import SentenceTransformer



OPENAI_KEY=os.getenv("OPENAI_KEY")

open_client = OpenAI(api_key=OPENAI_KEY)

data_path = 'data/data.csv'

ELASTIC_USERNAME = os.getenv("ELASTIC_USERNAME")
ELASTIC_PASSWORD = os.getenv("ELASTIC_PASSWORD")

ELASTIC_URL = os.getenv("ELASTIC_URL")
MODEL_NAME = os.getenv("MODEL_NAME")
INDEX_NAME = os.getenv("INDEX_NAME")

def load_documents():
      
    data_df = pd.read_csv(data_path).fillna('')

    documents = data_df.to_dict(orient='records')

    return documents



def mini_search(query):

    best_boost = {'Service_Category': 0.10638495651755087,
                    'Service_Type': 1.269946147222612,
                    'Link_to_Documentation': 1.5531045466189122,
                    'Google_Cloud_Product': 1.3250028735372683,
                    'Google_Cloud_Product_Description': 1.9395345731534959,
                    'AWS_Offering': 2.067143729150134,
                    'Azure_Offering': 0.799844469488588
                }
    

    documents = load_documents()

    text_fields = ["Service_Category", 
                   "Service_Type", 
                   "Link_to_Documentation", 
                   "Google_Cloud_Product", 
                   "Google_Cloud_Product_Description", 
                   "AWS_Offering", 
                   "Azure_Offering"]

    index = minsearch.Index(
        text_fields=text_fields,
        keyword_fields=['Id']
        )


    index.fit(documents)

    results = index.search(
            query=query,
            filter_dict={},
            boost_dict=best_boost,
            num_results=5
        )

    return results

def compute_rrf(rank, k=60):
    """ Our own implementation of the relevance score """
    return 1 / (k + rank)

def elastic_search(query,vector_query):

    

    es_client = Elasticsearch(ELASTIC_URL,verify_certs=False,basic_auth=(ELASTIC_USERNAME,ELASTIC_PASSWORD))
    


    knn_query = {
        "field": "General_Vector",
        "query_vector": vector_query,
        "k": 10,
        "num_candidates": 10000,
        "boost": 0.5,
    }

    keyword_query = {
        "bool": {
            "must": {
                "multi_match": {
                    "query": query,
                    "fields": ["Google_Cloud_Product^7","Google_Cloud_Product_Description^3","Service_Type"],
                    "type": "best_fields",
                    "boost": 0.5,
                }
            }
        }
    }

    knn_results = es_client.search(
        index=INDEX_NAME, 
        body={
            "knn": knn_query, 
            "size": 5
        }
    )['hits']['hits']
    
    keyword_results = es_client.search(
        index=INDEX_NAME, 
        body={
            "query": keyword_query, 
            "size": 5
        }
    )['hits']['hits']
    
    rrf_scores = {}
    k = 60
    # Calculate RRF using vector search results
    for rank, hit in enumerate(knn_results):
        doc_id = hit['_id']
        rrf_scores[doc_id] = compute_rrf(rank + 1, k)

    # Adding keyword search result scores
    for rank, hit in enumerate(keyword_results):
        doc_id = hit['_id']
        if doc_id in rrf_scores:
            rrf_scores[doc_id] += compute_rrf(rank + 1, k)
        else:
            rrf_scores[doc_id] = compute_rrf(rank + 1, k)

    # Sort RRF scores in descending order
    reranked_docs = sorted(rrf_scores.items(), key=lambda x: x[1], reverse=True)
    
    # Get top-K documents by the score
    final_results = []
    for doc_id, score in reranked_docs[:5]:
        doc = es_client.get(index=INDEX_NAME, id=doc_id)
        final_results.append(doc['_source'])
    
    return final_results



def build_prompt(query, search_results):

    context = ""

    for doc in search_results:
        context = context + entry_template.format(**doc) + "\n\n"


    prompt = prompt_template.format(question=query,context=context).strip()
    return prompt


def llm(prompt,model_choice):
    start_time = time.time()

    model = model_choice.split('/')[-1]

    response = open_client.chat.completions.create(
        model=model,
        messages=[{"role":"user","content": prompt}]
    )
    
    answer = response.choices[0].message.content

    tokens = {
            'prompt_tokens': response.usage.prompt_tokens,
            'completion_tokens': response.usage.completion_tokens,
            'total_tokens': response.usage.total_tokens
        }

    end_time = time.time()


    response_time = end_time - start_time


    return  answer, response_time , tokens


def rag(query,model_choice,search_engine):

    if search_engine == 'minisearch':
    
       search_results = mini_search(query)

    else:
       model = SentenceTransformer(MODEL_NAME)
       vector_query = model.encode(query)
       search_results = elastic_search(query,vector_query)

    prompt = build_prompt(query,search_results)

    result = llm(prompt,model_choice)

    return result

def rag_evaluation(answer_llm,query):
    
    
    prompt = eval_template.format(question=query,answer_llm=answer_llm)

    result = llm(prompt,'openai/gpt-4o')

    return result


def calculate_openai_cost(model, tokens):
    openai_cost = 0

    if model == 'openai/gpt-3.5-turbo':
        openai_cost = (tokens['prompt_tokens'] * 0.0015 + tokens['completion_tokens'] * 0.002) / 1000
    elif model in ['openai/gpt-4o', 'openai/gpt-4o-mini']:
        openai_cost = (tokens['prompt_tokens'] * 0.03 + tokens['completion_tokens'] * 0.06) / 1000

    return openai_cost


def get_answer(query,model,search_engine):

    print(ELASTIC_USERNAME,ELASTIC_PASSWORD,ELASTIC_URL)

    rag_answer, rag_response_time , rag_tokens = rag(query,model,search_engine)
    eval_answer, eval_response_time , eval_tokens = rag_evaluation(rag_answer,query)

    response_time = rag_response_time + eval_response_time

    json_eval = json.loads(eval_answer)
    relevance =  json_eval['Relevance']
    explanation = json_eval['Explanation']


    openai_cost = calculate_openai_cost(model, rag_tokens)
    
    
    return {
        'answer': rag_answer,
        'response_time': response_time,
        'relevance': relevance,
        'relevance_explanation': explanation,
        'model_used': model,
        'search_engine': search_engine,
        'prompt_tokens': rag_tokens['prompt_tokens'],
        'completion_tokens': rag_tokens['completion_tokens'],
        'total_tokens': rag_tokens['total_tokens'],
        'eval_prompt_tokens': eval_tokens['prompt_tokens'],
        'eval_completion_tokens': eval_tokens['completion_tokens'],
        'eval_total_tokens': eval_tokens['total_tokens'],
        'openai_cost': openai_cost
    }

   

