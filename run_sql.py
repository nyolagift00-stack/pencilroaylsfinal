import psycopg2

# Database connection
conn = psycopg2.connect(
    host='db.tjooofnjwwtgageayezr.supabase.co',
    port=5432,
    user='postgres',
    password='FnRoGA5BaWYm9pkh',
    database='postgres'
)

cursor = conn.cursor()

# Read and execute the seed.sql file
with open('supabase/seed.sql', 'r') as f:
    sql = f.read()

try:
    cursor.execute(sql)
    conn.commit()
    print("✅ Database tables created successfully!")
except Exception as e:
    print(f"❌ Error: {e}")
    conn.rollback()
finally:
    cursor.close()
    conn.close()
