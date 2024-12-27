#  Cloud Services Comparison Assistant



<p align="center">
  <img src="images/cover.jpg">
</p>

As a multi cloud engineer stay updated with the numerious services and 
resource across the three major cloud vendor can be challenging especially for beginners trying to switch from one vendor to another

The Cloud Services Comparison Assistant provides a conversational AI that helps
Engineers choose resources across the major cloud vendor and also get their alternatives with google cloud as the point of reference.


This project was implemented for 
[LLM Zoomcamp](https://github.com/DataTalksClub/llm-zoomcamp) -
a free course about LLMs and RAG.

<p align="center">
  <img src="images/image.png">
</p>


## Project overview

The Cloud Services Comparison Assistant is a RAG application designed to assist
cloud engineer as a comparative quide across the different major cloud vendor.

The main use cases include:

1. Google Cloud Service Selection: Recommending exercises based on the type
of activity, targeted muscle groups, or available equipment.
2. Other vendors Alternative: Replacing an exercise with suitable
alternatives.
3. Links to documentation (Google Cloud): Providing guidance on how to perform a
specific exercise.
4. Conversational Interaction: Making it easy to get information
without sifting through manuals or websites.

## Dataset

The dataset used in this project contains information about
various service, including:

Service category,Service type,Link to Documentation,Google Cloud product,Google Cloud product description,AWS offering,Azure offering
- **Service Category:** The name of the exercise (e.g., Push-Ups, Squats).
- **Service Type:** The general category of the exercise (e.g., Strength, Mobility, Cardio).
- **Google Cloud Product:** The part of the body primarily targeted by the exercise (e.g., Upper Body, Core, Lower Body).
- **Documentation Link:** The equipment needed for the exercise (e.g., Bodyweight, Dumbbells, Kettlebell).
- **Product Description:** The movement type (e.g., Push, Pull, Hold, Stretch).
- **AWS Offering:** The specific muscles engaged during
- **Azure Offering:** Step-by-step guidance on how to perform the

The dataset was extracted from googlre documentation and contains 222 records. It serves as the foundation for the Comparartive Cloud product recommendations and instructional support for Cloud Engineers aspiring to pick up multi-cloud with google as the reference point.

You can find the data in [`data/data.csv`](data/data.csv).

## Technologies

- Python 3.12
- Docker for containerization
- Kubernetes for container orchestration
- AWS as the cloud vendor for the various networking, compute, storage and kubernetes resources
- [Minsearch](https://github.com/alexeygrigorev/minsearch) for full-text search
- Streamlit as the web interface
- Grafana for monitoring
- RDS PostgreSQL for both the sreamlit and gradfana  backend
- OpenAI and Ollam as an LLM



## Running the application




## Using the application





## Experiments

We have the following notebooks:

- [`rag-test.ipynb`](notebooks/rag-test.ipynb): The RAG flow and evaluating the system.
- [`evaluation-data-generation.ipynb`](notebooks/evaluation-data-generation.ipynb): Generating the ground truth dataset for retrieval evaluation.

### Text Retrieval evaluation

The first approach - using `minsearch` without any boosting - gave the following metrics:

- Hit rate: 89%
- MRR: 75%

The improved version (with tuned boosting):

- Hit rate: 92%
- MRR: 81%

The best boosting parameters:

```python
best_boost = {'Service_Category': 0.10638495651755087,
  'Service_Type': 1.269946147222612,
  'Link_to_Documentation': 1.5531045466189122,
  'Google_Cloud_Product': 1.3250028735372683,
  'Google_Cloud_Product_Description': 1.9395345731534959,
  'AWS_Offering': 2.067143729150134,
  'Azure_Offering': 0.799844469488588}
```

The second approach - using `elastic search` without any boosting - gave the following metrics:

- Hit rate: 86%
- MRR: 75%

### Embedded Vector Retrieval evaluation

The first approach - using `elastic search` with only the cloud product description embeddings - gave the following metrics:

- Hit rate: 54%
- MRR: 40%

The improved version (with all fields concantenated and embedded) gave an improved metrics:

- Hit rate: 90%
- MRR: 78%

The second approach - using `elastic search` with all fields concantenated and embedded together with hybird search and reranking incoperated  - gave the following metrics:

- Hit rate: 95%
- MRR: 84%

### RAG flow evaluation

We used the LLM-as-a-Judge metric to evaluate the quality
of our RAG flow.

For `gpt-4o-mini`, in a sample with 200 records, we had:

- 167 (64%) `RELEVANT`
- 30 (31%) `PARTLY_RELEVANT`
- 3 (5%) `NON_RELEVANT`



## Monitoring

We use Grafana for monitoring the application. 

It's accessible at [localhost:3000](http://localhost:3000):

- Login: "admin"
- Password: "admin"

### Dashboards

<p align="center">
  <img src="images/dash.png">
</p>

The monitoring dashboard contains several panels:

1. **Last 5 Conversations (Table):** Displays a table showing the five most recent conversations, including details such as the question, answer, relevance, and timestamp. This panel helps monitor recent interactions with users.
2. **+1/-1 (Pie Chart):** A pie chart that visualizes the feedback from users, showing the count of positive (thumbs up) and negative (thumbs down) feedback received. This panel helps track user satisfaction.
3. **Relevancy (Gauge):** A gauge chart representing the relevance of the responses provided during conversations. The chart categorizes relevance and indicates thresholds using different colors to highlight varying levels of response quality.
4. **OpenAI Cost (Time Series):** A time series line chart depicting the cost associated with OpenAI usage over time. This panel helps monitor and analyze the expenditure linked to the AI model's usage.
5. **Tokens (Time Series):** Another time series chart that tracks the number of tokens used in conversations over time. This helps to understand the usage patterns and the volume of data processed.
6. **Model Used (Bar Chart):** A bar chart displaying the count of conversations based on the different models used. This panel provides insights into which AI models are most frequently used.
7. **Response Time (Time Series):** A time series chart showing the response time of conversations over time. This panel is useful for identifying performance issues and ensuring the system's responsiveness.




## Acknowledgements 

I thank the course participants for all your energy
and positive feedback as well as the course sponsors for
making it possible to run this course for free. 

I hope you enjoyed doing the course =)