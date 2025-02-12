import os
import psycopg2
from psycopg2.extras import DictCursor
from datetime import datetime
from zoneinfo import ZoneInfo

tz = ZoneInfo("Europe/Berlin")




def get_db_connection(hostname,password,database,user):
    return psycopg2.connect(
        host=hostname,
        database=database,
        user=user,
        password=password,
    )


def init_db(hostname,password,database,user):
    conn = get_db_connection(hostname,password,database,user)
    try:
        with conn.cursor() as cur:
            cur.execute("DROP TABLE IF EXISTS feedback")
            cur.execute("DROP TABLE IF EXISTS conversations")

            cur.execute("""
                CREATE TABLE conversations (
                    id TEXT PRIMARY KEY,
                    question TEXT NOT NULL,
                    answer TEXT NOT NULL,
                    model_used TEXT NOT NULL,
                    search_engine TEXT NOT NULL,
                    response_time FLOAT NOT NULL,
                    relevance TEXT NOT NULL,
                    relevance_explanation TEXT NOT NULL,
                    prompt_tokens INTEGER NOT NULL,
                    completion_tokens INTEGER NOT NULL,
                    total_tokens INTEGER NOT NULL,
                    eval_prompt_tokens INTEGER NOT NULL,
                    eval_completion_tokens INTEGER NOT NULL,
                    eval_total_tokens INTEGER NOT NULL,
                    openai_cost FLOAT NOT NULL,
                    timestamp TIMESTAMP WITH TIME ZONE NOT NULL
                )
            """)

       
            cur.execute("""
                CREATE TABLE feedback (
                    id SERIAL PRIMARY KEY,
                    conversation_id TEXT REFERENCES conversations(id),
                    feedback INTEGER NOT NULL,
                    timestamp TIMESTAMP WITH TIME ZONE NOT NULL
                )
            """)
        conn.commit()
    finally:
        conn.close()


def save_conversation( hostname,password,database,user,conversation_id, question, answer_data, timestamp=None):
    
    
    if timestamp is None:
        timestamp = datetime.now(tz)
    
    conn = get_db_connection(hostname,password,database,user)
    try:
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO conversations 
                (id, question, answer, model_used,search_engine, response_time, relevance, 
                relevance_explanation, prompt_tokens, completion_tokens, total_tokens, 
                eval_prompt_tokens, eval_completion_tokens, eval_total_tokens, openai_cost, timestamp)
                VALUES (%s, %s, %s, %s, %s,%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, COALESCE(%s, CURRENT_TIMESTAMP))
            """,
                (
                    conversation_id,
                    question,
                    answer_data["answer"],
                    answer_data["model_used"],
                    answer_data["search_engine"],
                    answer_data["response_time"],
                    answer_data["relevance"],
                    answer_data["relevance_explanation"],
                    answer_data["prompt_tokens"],
                    answer_data["completion_tokens"],
                    answer_data["total_tokens"],
                    answer_data["eval_prompt_tokens"],
                    answer_data["eval_completion_tokens"],
                    answer_data["eval_total_tokens"],
                    answer_data["openai_cost"],
                    timestamp,
                ),
            )
        conn.commit()
    finally:
        conn.close()
    


def save_feedback(hostname,password,database,user, conversation_id, feedback,timestamp=None):
    if timestamp is None:
        timestamp = datetime.now(tz)

    conn = get_db_connection(hostname,password,database,user)
    try:
        with conn.cursor() as cur:
            cur.execute(
                "INSERT INTO feedback (conversation_id, feedback, timestamp) VALUES (%s, %s, COALESCE(%s, CURRENT_TIMESTAMP))",
                (conversation_id, feedback, timestamp),
            )
        conn.commit()
    finally:
        conn.close()




def get_recent_conversations(hostname,password,database,user,limit=5,relevance=None):
    conn = get_db_connection(hostname,password,database,user)
    try:
        with conn.cursor(cursor_factory=DictCursor) as cur:
            query = """
                SELECT c.*, f.feedback
                FROM conversations c
                LEFT JOIN feedback f ON c.id = f.conversation_id
            """
            if relevance:
                query += f" WHERE c.relevance = '{relevance}'"
            query += " ORDER BY c.timestamp DESC LIMIT %s"

            cur.execute(query, (limit,))
            return cur.fetchall()
    finally:
        conn.close()


def get_feedback_stats(hostname,password,database,user):
    conn = get_db_connection(hostname,password,database,user)
    try:
        with conn.cursor(cursor_factory=DictCursor) as cur:
            cur.execute("""
                SELECT 
                    SUM(CASE WHEN feedback > 0 THEN 1 ELSE 0 END) as thumbs_up,
                    SUM(CASE WHEN feedback < 0 THEN 1 ELSE 0 END) as thumbs_down
                FROM feedback
            """)
            return cur.fetchone()
    finally:
        conn.close()

