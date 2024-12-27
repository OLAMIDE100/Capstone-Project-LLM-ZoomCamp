import os
import requests
import pandas as pd
from sentence_transformers import SentenceTransformer
from elasticsearch import Elasticsearch
from tqdm.auto import tqdm
from dotenv import load_dotenv
import json

from db import init_db

load_dotenv()

hostname=os.getenv("POSTGRES_HOST")
database=os.getenv("POSTGRES_DB")
user=os.getenv("POSTGRES_USER")
password=os.getenv("POSTGRES_PASSWORD")




ELASTIC_USERNAME = os.getenv("ELASTIC_USERNAME")
ELASTIC_PASSWORD = os.getenv("ELASTIC_PASSWORD")

ELASTIC_URL = os.getenv("ELASTIC_URL")
MODEL_NAME = os.getenv("MODEL_NAME")
INDEX_NAME = os.getenv("INDEX_NAME")



def fetch_documents():
    print("Fetching documents...")
    with open("data/documents_id.json","rt") as file_in:
       documents = json.load(file_in)
    print(f"Fetched {len(documents)} documents")
    return documents





def load_model():
    print(f"Loading model: {MODEL_NAME}")
    return SentenceTransformer(MODEL_NAME)


def setup_elasticsearch():
    print("Setting up Elasticsearch...")
   
    es_client = Elasticsearch(ELASTIC_URL,verify_certs=False,basic_auth=(ELASTIC_USERNAME,ELASTIC_PASSWORD))

    index_settings = {
        "settings": {
            "number_of_shards": 1,
            "number_of_replicas": 1
        },
        "mappings": {
            "properties": {
                "Service_Category": {"type": "text"},
                "Service_Type": {"type": "text"},
                "Link_to_Documentation": {"type": "text"},
                "Google_Cloud_Product": {"type": "text"},
                "Google_Cloud_Product_Description": {"type": "text"},
                "AWS_Offering": {"type": "text"},
                "Azure_Offering": {"type": "text"},
                "Id": {"type": "keyword"},
                "General_Vector": {"type": "dense_vector","dims": 768,"index": True,"similarity":"cosine"},


            }
        }
    }

    es_client.indices.delete(index=INDEX_NAME, ignore_unavailable=True)
    es_client.indices.create(index=INDEX_NAME, body=index_settings)
    print(f"Elasticsearch index '{INDEX_NAME}' created")
    return es_client


def index_documents(es_client, documents, model):
    print("Indexing documents...")
    for doc in tqdm(documents):
      qt = doc["Service_Type"] + ' ' + doc["Link_to_Documentation"] + ' ' + doc["Google_Cloud_Product"] + ' ' + doc["Google_Cloud_Product_Description"] + ' ' + doc["AWS_Offering"] + ' ' + doc['Azure_Offering']
      doc['General_Vector'] = model.encode(qt)
      es_client.index(index=INDEX_NAME, document=doc)
    print(f"Indexed {len(documents)} documents")


def main():
   
    print("Starting the indexing process...")

    documents = fetch_documents()
    model = load_model()
    es_client = setup_elasticsearch()
    index_documents(es_client, documents, model)
  

    print("Initializing database...")
    init_db(hostname,password,database,user)

    print("Indexing process completed successfully!")


if __name__ == "__main__":
    main()

