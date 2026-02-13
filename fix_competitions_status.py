#!/usr/bin/env python3
"""
Fix competitions table status field
Converts "Pending" statuses to "active" and ensures proper status values
"""

import psycopg2
import sys

# Database connection
conn = psycopg2.connect(
    host='db.tjooofnjwwtgageayezr.supabase.co',
    port=5432,
    user='postgres',
    password='FnRoGA5BaWYm9pkh',
    database='postgres'
)

cursor = conn.cursor()

try:
    # Read and execute the migration
    with open('supabase/migrations/003_fix_competitions_status.sql', 'r') as f:
        sql = f.read()

    cursor.execute(sql)
    conn.commit()
    print("✅ Competitions table fixed successfully!")
    print("   - 'Pending' statuses converted to 'active'")
    print("   - Status field now properly set")
    print("\n📊 Verifying competitions status:")
    
    # Verify the fix
    cursor.execute("SELECT id, name, status FROM competitions ORDER BY created_at DESC LIMIT 10;")
    results = cursor.fetchall()
    
    for comp_id, name, status in results:
        print(f"   • {name}: {status}")
        
except Exception as e:
    print(f"❌ Error fixing competitions: {e}")
    conn.rollback()
    sys.exit(1)
finally:
    cursor.close()
    conn.close()
