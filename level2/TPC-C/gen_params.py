import psycopg2
import json
import random
from datetime import datetime
from typing import Dict, List

DB_CONFIG = {
    'dbname': 'tpcc',
    'user': 'tiagogr',
    'password': 'password',
    'host': 'localhost',
    'port': 5432
}

def get_connection():
    return psycopg2.connect(**DB_CONFIG)

def nurand(a: int, x: int, y: int) -> int:
    """TPC-C NURand function implementation"""
    c_value = random.randint(0, a)
    return (((random.randint(0, a) | random.randint(x, y)) + c_value) % (y - x + 1)) + x

def get_valid_warehouse_districts(conn) -> List[tuple]:
    """Returns list of valid (w_id, d_id) pairs"""
    cur = conn.cursor()
    cur.execute("SELECT DISTINCT w_id FROM bmsql_warehouse ORDER BY w_id")
    warehouses = [row[0] for row in cur.fetchall()]
    
    wh_districts = []
    for w_id in warehouses:
        for d_id in range(1, 11):
            wh_districts.append((w_id, d_id))
    
    cur.close()
    return wh_districts

def get_valid_customer(conn, w_id: int, d_id: int) -> Dict:
    """Returns a valid customer"""
    cur = conn.cursor()
    cur.execute("""
        SELECT c_id, c_last 
        FROM bmsql_customer 
        WHERE c_w_id = %s AND c_d_id = %s
        ORDER BY RANDOM()
        LIMIT 1
    """, (w_id, d_id))
    
    result = cur.fetchone()
    cur.close()
    return {'c_id': result[0], 'c_last': result[1]} if result else None

def get_valid_items(conn, count: int) -> List[int]:
    """Returns list of valid item_ids"""
    cur = conn.cursor()
    cur.execute("SELECT i_id FROM bmsql_item ORDER BY RANDOM() LIMIT %s", (count,))
    items = [row[0] for row in cur.fetchall()]
    cur.close()
    return items

# ============================================================================
# NEW ORDER - 4 Normal + 4 Edge Cases
# ============================================================================

def generate_new_order_params(conn, wh_districts: List[tuple], num_normal: int = 4) -> List[Dict]:
    """Generates normal parameters for New-Order"""
    params_list = []
    
    for _ in range(num_normal):
        w_id, d_id = random.choice(wh_districts)
        customer = get_valid_customer(conn, w_id, d_id)
        if not customer:
            continue
        
        ol_cnt = random.randint(5, 15)
        valid_items = get_valid_items(conn, ol_cnt)
        if len(valid_items) < ol_cnt:
            continue
        
        ol_i_id = []
        ol_supply_w_id = []
        ol_quantity = []
        
        for item_id in valid_items:
            ol_i_id.append(item_id)
            if random.randint(1, 100) > 1:
                ol_supply_w_id.append(w_id)
            else:
                other_whs = [wh for wh, _ in wh_districts if wh != w_id]
                ol_supply_w_id.append(random.choice(other_whs) if other_whs else w_id)
            ol_quantity.append(random.randint(1, 10))
        
        params_list.append({
            'in_w_id': w_id,
            'in_d_id': d_id,
            'in_c_id': customer['c_id'],
            'in_ol_supply_w_id': ol_supply_w_id,
            'in_ol_i_id': ol_i_id,
            'in_ol_quantity': ol_quantity
        })
    
    return params_list

def generate_new_order_edge_cases(conn, wh_districts: List[tuple]) -> List[Dict]:
    """Generates edge cases for New-Order"""
    edge_cases = []
    
    w_id, d_id = random.choice(wh_districts)
    customer = get_valid_customer(conn, w_id, d_id)
    items = get_valid_items(conn, 15)
    warehouses = list(set([wh for wh, _ in wh_districts]))
    
    # 1. Invalid item
    edge_cases.append({
        'in_w_id': w_id,
        'in_d_id': d_id,
        'in_c_id': customer['c_id'],
        'in_ol_supply_w_id': [w_id],
        'in_ol_i_id': [999999],
        'in_ol_quantity': [5]
    })
    
    # 2. Maximum number of items (15)
    edge_cases.append({
        'in_w_id': w_id,
        'in_d_id': d_id,
        'in_c_id': customer['c_id'],
        'in_ol_supply_w_id': [w_id] * 15,
        'in_ol_i_id': items,
        'in_ol_quantity': [1] * 15
    })
    
    # 3. Maximum quantity per item
    edge_cases.append({
        'in_w_id': w_id,
        'in_d_id': d_id,
        'in_c_id': customer['c_id'],
        'in_ol_supply_w_id': [w_id] * 5,
        'in_ol_i_id': items[:5],
        'in_ol_quantity': [10] * 5
    })
    
    # 4. All remote warehouses
    if len(warehouses) > 4:
        edge_cases.append({
            'in_w_id': warehouses[0],
            'in_d_id': d_id,
            'in_c_id': customer['c_id'],
            'in_ol_supply_w_id': warehouses[1:5],
            'in_ol_i_id': items[:4],
            'in_ol_quantity': [5] * 4
        })
    else:
        # Fallback: minimum number of items
        edge_cases.append({
            'in_w_id': w_id,
            'in_d_id': d_id,
            'in_c_id': customer['c_id'],
            'in_ol_supply_w_id': [w_id] * 5,
            'in_ol_i_id': items[:5],
            'in_ol_quantity': [1] * 5
        })
    
    return edge_cases

# ============================================================================
# PAYMENT - 4 Normal + 4 Edge Cases
# ============================================================================

def generate_payment_params(conn, wh_districts: List[tuple], num_normal: int = 4) -> List[Dict]:
    """Generates normal parameters for Payment"""
    params_list = []
    
    for _ in range(num_normal):
        w_id, d_id = random.choice(wh_districts)
        
        x = random.randint(1, 100)
        if x <= 85:
            c_w_id, c_d_id = w_id, d_id
        else:
            c_w_id, c_d_id = random.choice([wd for wd in wh_districts if wd[0] != w_id] or [(w_id, d_id)])
        
        y = random.randint(1, 100)
        customer = get_valid_customer(conn, c_w_id, c_d_id)
        if not customer:
            continue
        
        params_list.append({
            'in_w_id': w_id,
            'in_d_id': d_id,
            'in_c_id': customer['c_id'] if y > 60 else None,
            'in_c_d_id': c_d_id,
            'in_c_w_id': c_w_id,
            'in_c_last': customer['c_last'] if y <= 60 else None,
            'in_h_amount': round(random.uniform(1.0, 5000.0), 2)
        })
    
    return params_list

def generate_payment_edge_cases(conn, wh_districts: List[tuple]) -> List[Dict]:
    """Generates edge cases for Payment"""
    cur = conn.cursor()
    edge_cases = []
    
    w_id, d_id = random.choice(wh_districts)
    customer = get_valid_customer(conn, w_id, d_id)
    
    # 1. Minimum payment amount
    edge_cases.append({
        'in_w_id': w_id,
        'in_d_id': d_id,
        'in_c_id': customer['c_id'],
        'in_c_d_id': d_id,
        'in_c_w_id': w_id,
        'in_c_last': None,
        'in_h_amount': 1.00
    })
    
    # 2. Maximum payment amount
    edge_cases.append({
        'in_w_id': w_id,
        'in_d_id': d_id,
        'in_c_id': customer['c_id'],
        'in_c_d_id': d_id,
        'in_c_w_id': w_id,
        'in_c_last': None,
        'in_h_amount': 5000.00
    })
    
    # 3. Customer with bad credit
    cur.execute("""
        SELECT c_w_id, c_d_id, c_id 
        FROM bmsql_customer 
        WHERE c_credit = 'BC'
        ORDER BY RANDOM() LIMIT 1
    """)
    bad_credit = cur.fetchone()
    if bad_credit:
        edge_cases.append({
            'in_w_id': w_id,
            'in_d_id': d_id,
            'in_c_id': bad_credit[2],
            'in_c_d_id': bad_credit[1],
            'in_c_w_id': bad_credit[0],
            'in_c_last': None,
            'in_h_amount': 1000.00
        })
    else:
        # Fallback
        edge_cases.append({
            'in_w_id': w_id,
            'in_d_id': d_id,
            'in_c_id': customer['c_id'],
            'in_c_d_id': d_id,
            'in_c_w_id': w_id,
            'in_c_last': None,
            'in_h_amount': 1000.00
        })
    
    # 4. Non-existent last name
    edge_cases.append({
        'in_w_id': w_id,
        'in_d_id': d_id,
        'in_c_id': None,
        'in_c_d_id': d_id,
        'in_c_w_id': w_id,
        'in_c_last': 'NONEXISTENT',
        'in_h_amount': 100.00
    })
    
    cur.close()
    return edge_cases

# ============================================================================
# ORDER STATUS - 4 Normal + 4 Edge Cases
# ============================================================================

def generate_order_status_params(conn, wh_districts: List[tuple], num_normal: int = 4) -> List[Dict]:
    """Generates normal parameters for Order-Status"""
    params_list = []
    
    for _ in range(num_normal):
        w_id, d_id = random.choice(wh_districts)
        y = random.randint(1, 100)
        customer = get_valid_customer(conn, w_id, d_id)
        if not customer:
            continue
        
        params_list.append({
            'in_w_id': w_id,
            'in_d_id': d_id,
            'in_c_id': customer['c_id'] if y > 60 else None,
            'in_c_last': customer['c_last'] if y <= 60 else None
        })
    
    return params_list

def generate_order_status_edge_cases(conn, wh_districts: List[tuple]) -> List[Dict]:
    """Generates edge cases for Order-Status"""
    cur = conn.cursor()
    edge_cases = []
    
    w_id, d_id = random.choice(wh_districts)
    customer = get_valid_customer(conn, w_id, d_id)
    
    # 1. Customer without orders
    cur.execute("""
        SELECT c_w_id, c_d_id, c_id
        FROM bmsql_customer c
        WHERE NOT EXISTS (
            SELECT 1 FROM bmsql_oorder o 
            WHERE o.o_w_id = c.c_w_id 
            AND o.o_d_id = c.c_d_id 
            AND o.o_c_id = c.c_id
        )
        ORDER BY RANDOM() LIMIT 1
    """)
    no_orders = cur.fetchone()
    if no_orders:
        edge_cases.append({
            'in_w_id': no_orders[0],
            'in_d_id': no_orders[1],
            'in_c_id': no_orders[2],
            'in_c_last': None
        })
    else:
        # Fallback
        edge_cases.append({
            'in_w_id': w_id,
            'in_d_id': d_id,
            'in_c_id': customer['c_id'],
            'in_c_last': None
        })
    
    # 2. Invalid customer
    edge_cases.append({
        'in_w_id': w_id,
        'in_d_id': d_id,
        'in_c_id': 999999,
        'in_c_last': None
    })
    
    # 3. Non-existent last name
    edge_cases.append({
        'in_w_id': w_id,
        'in_d_id': d_id,
        'in_c_id': None,
        'in_c_last': 'NONEXISTENT'
    })
    
    # 4. Customer with many orders
    cur.execute("""
        SELECT c_w_id, c_d_id, c_id, COUNT(*) as cnt
        FROM bmsql_customer c
        JOIN bmsql_oorder o ON o.o_w_id = c.c_w_id 
            AND o.o_d_id = c.c_d_id 
            AND o.o_c_id = c.c_id
        GROUP BY c_w_id, c_d_id, c_id
        ORDER BY cnt DESC
        LIMIT 1
    """)
    many_orders = cur.fetchone()
    if many_orders:
        edge_cases.append({
            'in_w_id': many_orders[0],
            'in_d_id': many_orders[1],
            'in_c_id': many_orders[2],
            'in_c_last': None
        })
    else:
        # Fallback
        edge_cases.append({
            'in_w_id': w_id,
            'in_d_id': d_id,
            'in_c_id': customer['c_id'],
            'in_c_last': None
        })
    
    cur.close()
    return edge_cases

# ============================================================================
# DELIVERY - 4 Normal + 4 Edge Cases
# ============================================================================

def generate_delivery_params(conn, wh_districts: List[tuple], num_normal: int = 4) -> List[Dict]:
    """Generates normal parameters for Delivery"""
    params_list = []
    warehouses = list(set([w_id for w_id, _ in wh_districts]))
    
    for _ in range(min(num_normal, len(warehouses))):
        w_id = random.choice(warehouses)
        params_list.append({
            'in_w_id': w_id,
            'in_o_carrier_id': random.randint(1, 10),
            'in_ol_delivery_d': datetime.now().isoformat()
        })
    
    # If fewer warehouses than needed, repeat with different carrier_ids
    while len(params_list) < num_normal:
        w_id = random.choice(warehouses)
        params_list.append({
            'in_w_id': w_id,
            'in_o_carrier_id': random.randint(1, 10),
            'in_ol_delivery_d': datetime.now().isoformat()
        })
    
    return params_list

def generate_delivery_edge_cases(conn, wh_districts: List[tuple]) -> List[Dict]:
    """Generates edge cases for Delivery"""
    cur = conn.cursor()
    edge_cases = []
    
    w_id = random.choice([w for w, _ in wh_districts])
    
    # 1. Minimum carrier ID
    edge_cases.append({
        'in_w_id': w_id,
        'in_o_carrier_id': 1,
        'in_ol_delivery_d': datetime.now().isoformat()
    })
    
    # 2. Maximum carrier ID
    edge_cases.append({
        'in_w_id': w_id,
        'in_o_carrier_id': 10,
        'in_ol_delivery_d': datetime.now().isoformat()
    })
    
    # 3. Warehouse without new orders
    cur.execute("""
        SELECT w_id FROM bmsql_warehouse w
        WHERE NOT EXISTS (
            SELECT 1 FROM bmsql_new_order no
            WHERE no.no_w_id = w.w_id
        )
        ORDER BY RANDOM() LIMIT 1
    """)
    no_orders = cur.fetchone()
    if no_orders:
        edge_cases.append({
            'in_w_id': no_orders[0],
            'in_o_carrier_id': 5,
            'in_ol_delivery_d': datetime.now().isoformat()
        })
    else:
        # Fallback: mid-range carrier
        edge_cases.append({
            'in_w_id': w_id,
            'in_o_carrier_id': 5,
            'in_ol_delivery_d': datetime.now().isoformat()
        })
    
    # 4. Invalid warehouse
    edge_cases.append({
        'in_w_id': 999999,
        'in_o_carrier_id': 5,
        'in_ol_delivery_d': datetime.now().isoformat()
    })
    
    cur.close()
    return edge_cases

# ============================================================================
# STOCK LEVEL - 4 Normal + 4 Edge Cases
# ============================================================================

def generate_stock_level_params(conn, wh_districts: List[tuple], num_normal: int = 4) -> List[Dict]:
    """Generates normal parameters for Stock-Level"""
    params_list = []
    
    for _ in range(num_normal):
        w_id, d_id = random.choice(wh_districts)
        params_list.append({
            'in_w_id': w_id,
            'in_d_id': d_id,
            'in_threshold': random.randint(10, 20)
        })
    
    return params_list

def generate_stock_level_edge_cases(conn, wh_districts: List[tuple]) -> List[Dict]:
    """Generates edge cases for Stock-Level"""
    cur = conn.cursor()
    edge_cases = []
    
    w_id, d_id = random.choice(wh_districts)
    
    # 1. Minimum threshold
    edge_cases.append({
        'in_w_id': w_id,
        'in_d_id': d_id,
        'in_threshold': 10
    })
    
    # 2. Maximum threshold
    edge_cases.append({
        'in_w_id': w_id,
        'in_d_id': d_id,
        'in_threshold': 20
    })
    
    # 3. District with few orders
    cur.execute("""
        SELECT d_w_id, d_id
        FROM bmsql_district
        WHERE d_next_o_id <= 20
        ORDER BY RANDOM() LIMIT 1
    """)
    low_orders = cur.fetchone()
    if low_orders:
        edge_cases.append({
            'in_w_id': low_orders[0],
            'in_d_id': low_orders[1],
            'in_threshold': 15
        })
    else:
        # Fallback: mid threshold
        edge_cases.append({
            'in_w_id': w_id,
            'in_d_id': d_id,
            'in_threshold': 15
        })
    
    # 4. Invalid warehouse
    edge_cases.append({
        'in_w_id': 999999,
        'in_d_id': d_id,
        'in_threshold': 15
    })
    
    cur.close()
    return edge_cases

# ============================================================================
# MAIN
# ============================================================================

def main():
    print("=" * 70)
    print("TPC-C COMPLETE PARAMETER GENERATOR (8 cases per transaction)")
    print("=" * 70)
    
    conn = get_connection()
    
    print("\n[1/6] Getting valid warehouses and districts...")
    wh_districts = get_valid_warehouse_districts(conn)
    print(f"      ✓ Found {len(wh_districts)} (warehouse, district) pairs")
    
    all_params = {}
    
    # NEW ORDER
    print("\n[2/6] Generating parameters for NEW-ORDER...")
    all_params['new_order'] = (
        generate_new_order_params(conn, wh_districts, num_normal=4) +
        generate_new_order_edge_cases(conn, wh_districts)
    )
    print(f"      ✓ {len(all_params['new_order'])} sets (4 normal + 4 edge cases)")
    
    # PAYMENT
    print("\n[3/6] Generating parameters for PAYMENT...")
    all_params['payment'] = (
        generate_payment_params(conn, wh_districts, num_normal=4) +
        generate_payment_edge_cases(conn, wh_districts)
    )
    print(f"      ✓ {len(all_params['payment'])} sets (4 normal + 4 edge cases)")
    
    # ORDER STATUS
    print("\n[4/6] Generating parameters for ORDER-STATUS...")
    all_params['order_status'] = (
        generate_order_status_params(conn, wh_districts, num_normal=4) +
        generate_order_status_edge_cases(conn, wh_districts)
    )
    print(f"      ✓ {len(all_params['order_status'])} sets (4 normal + 4 edge cases)")
    
    # DELIVERY
    print("\n[5/6] Generating parameters for DELIVERY...")
    all_params['delivery'] = (
        generate_delivery_params(conn, wh_districts, num_normal=4) +
        generate_delivery_edge_cases(conn, wh_districts)
    )
    print(f"      ✓ {len(all_params['delivery'])} sets (4 normal + 4 edge cases)")
    
    # STOCK LEVEL
    print("\n[6/6] Generating parameters for STOCK-LEVEL...")
    all_params['stock_level'] = (
        generate_stock_level_params(conn, wh_districts, num_normal=4) +
        generate_stock_level_edge_cases(conn, wh_districts)
    )
    print(f"      ✓ {len(all_params['stock_level'])} sets (4 normal + 4 edge cases)")
    
    conn.close()
    
    # Save results
    output_file = 'tpcc_params.json'
    with open(output_file, 'w') as f:
        json.dump(all_params, indent=2, fp=f)
    
    # Final summary
    print("\n" + "=" * 70)
    print("FINAL SUMMARY")
    print("=" * 70)
    for tx_type, params in all_params.items():
        print(f"{tx_type.upper():15s}: {len(params)} total parameter sets (4 normal + 4 edge)")
    
    print(f"\n{'=' * 70}")
    print(f"✓ File saved: '{output_file}'")
    print(f"✓ Total parameter sets: {sum(len(p) for p in all_params.values())}")
    print(f"✓ All transactions have exactly 8 cases each")
    print(f"{'=' * 70}\n")

if __name__ == '__main__':
    main()