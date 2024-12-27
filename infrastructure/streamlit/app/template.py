prompt_template = """
You're a multi cloud architect i.e google cloud, AWS, Azure. 
Answer the QUESTION based on the CONTEXT from our cloud comparative guide database.
Use only the facts from the CONTEXT when answering the QUESTION.

QUESTION: {question}

CONTEXT:
{context}
""".strip()


entry_template = """
Service category: {Service_Category}
Service type: {Service_Type}
Link to Documentation: {Link_to_Documentation}
Google Cloud product: {Google_Cloud_Product}
Google Cloud product description: {Google_Cloud_Product_Description}
AWS offering: {AWS_Offering}
Azure offering: {Azure_Offering}
""".strip()


eval_template = """
You are an expert evaluator for a RAG system.
Your task is to analyze the relevance of the generated answer to the given question.
Based on the relevance of the generated answer, you will classify it
as "NON_RELEVANT", "PARTLY_RELEVANT", or "RELEVANT".

Here is the data for evaluation:

Question: {question}
Generated Answer: {answer_llm}

Please analyze the content and context of the generated answer in relation to the question
and provide your evaluation in parsable JSON without using code blocks:

{{
  "Relevance": "NON_RELEVANT" | "PARTLY_RELEVANT" | "RELEVANT",
  "Explanation": "[Provide a brief explanation for your evaluation]"
}}
""".strip()