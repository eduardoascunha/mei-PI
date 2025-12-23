import psycopg2
import json
import os
import re
import subprocess
from contextlib import contextmanager

# ============================================================================
# CONFIGURATION
# ============================================================================
DB_CONFIG = {
    'dbname': 'tpcc', 'user': 'tiagogr', 'password': 'password',
    'host': 'localhost', 'port': 5432
}

TRANSACTIONS_DIR = 'llama/results_FS2E_COT_06'
RESULTS_DIR = 'llama/results_FS2E_COT_06/results'

#TRANSACTIONS_DIR = 'original_transactions2/functions'
#RESULTS_DIR = 'original_transactions2/results'

PARAMS_FILE = 'tpcc_params.json'
SNAPSHOTS_DIR = 'snapshots'

# Mapping: tx_type -> (file, function params)
TX_CONFIG = {
    'new_order': ('new_order.sql', 
                  ['in_w_id', 'in_d_id', 'in_c_id', 'in_ol_supply_w_id', 'in_ol_i_id', 'in_ol_quantity']),
    'payment': ('payment.sql',
                ['in_w_id', 'in_d_id', 'in_c_id', 'in_c_d_id', 'in_c_w_id', 'in_c_last', 'in_h_amount']),
    'order_status': ('order_status.sql',
                     ['in_w_id', 'in_d_id', 'in_c_id', 'in_c_last']),
    'delivery': ('delivery.sql',
                 ['in_w_id', 'in_o_carrier_id', 'in_ol_delivery_d']),
    'stock_level': ('stock_level.sql',
                    ['in_w_id', 'in_d_id', 'in_threshold']),
}

# All TPC-C tables
ALL_TABLES = [
    'bmsql_warehouse', 'bmsql_district', 'bmsql_customer', 'bmsql_stock',
    'bmsql_item', 'bmsql_oorder', 'bmsql_order_line', 'bmsql_new_order', 'bmsql_history'
]

# Tables that each transaction MUST modify (according to TPC-C specification)
EXPECTED_MODIFICATIONS = {
    'new_order': {'bmsql_district', 'bmsql_oorder', 'bmsql_new_order', 'bmsql_order_line', 'bmsql_stock'},
    'payment': {'bmsql_warehouse', 'bmsql_district', 'bmsql_customer', 'bmsql_history'},
    'order_status': set(),  # read-only
    'delivery': {'bmsql_new_order', 'bmsql_oorder', 'bmsql_order_line', 'bmsql_customer'},
    'stock_level': set(),  # read-only
}

class TPCCExecutor:
    def __init__(self):
        self.conn = None
        self.func_names = {}
        os.makedirs(SNAPSHOTS_DIR, exist_ok=True)
        os.makedirs(RESULTS_DIR, exist_ok=True)

    # ---- Connection ----
    def connect(self):
        self.conn = psycopg2.connect(**DB_CONFIG)
        self.conn.autocommit = False

    def disconnect(self):
        if self.conn:
            self.conn.close()
            self.conn = None

    @contextmanager
    def cursor(self):
        cur = self.conn.cursor()
        try:
            yield cur
        finally:
            cur.close()

    # ---- SQL Functions ----
    def extract_func_name(self, sql_file):
        if not os.path.exists(sql_file):
            return None
        try:
            content = open(sql_file, 'r').read()
            match = re.search(r'CREATE\s+(?:OR\s+REPLACE\s+)?FUNCTION\s+(\w+)\s*\(', content, re.I)
            return match.group(1) if match else None
        except Exception as e:
            print(f"    ⚠ Error reading file {sql_file}: {e}")
            return None

    def install_functions(self):
        """Installs all SQL functions (drop + create)"""
        print("\nInstalling SQL functions...")
        for tx_type, (filename, _) in TX_CONFIG.items():
            sql_file = os.path.join(TRANSACTIONS_DIR, filename)
            
            # Extract function name
            func_name = self.extract_func_name(sql_file)
            
            if not func_name:
                print(f"  ✗ {tx_type}: Function name not found in {filename} - WILL BE SKIPPED")
                continue
            
            self.func_names[tx_type] = func_name
            
            try:
                with self.cursor() as cur:
                    cur.execute(f"DROP FUNCTION IF EXISTS {func_name} CASCADE")
                    cur.execute(open(sql_file).read())
                self.conn.commit()
                print(f"  ✓ {tx_type}: {func_name}")
            except Exception as e:
                self.conn.rollback()  # Rollback to recover from error state
                print(f"  ✗ {tx_type}: Error installing function - {e}")
                # Remove from available functions list
                if tx_type in self.func_names:
                    del self.func_names[tx_type]

    # ---- Snapshots ----
    def _run_pg_cmd(self, cmd):
        env = {**os.environ, 'PGPASSWORD': DB_CONFIG['password']}
        return subprocess.run(cmd, env=env, capture_output=True, text=True)

    def create_snapshot(self, name='initial_state'):
        path = os.path.join(SNAPSHOTS_DIR, f'{name}.sql')
        self._run_pg_cmd([
            'pg_dump', '-h', DB_CONFIG['host'], '-p', str(DB_CONFIG['port']),
            '-U', DB_CONFIG['user'], '-d', DB_CONFIG['dbname'], '-F', 'c', '-f', path
        ])
        print(f"✓ Snapshot created: {name}")

    def restore_snapshot(self, name='initial_state'):
        path = os.path.join(SNAPSHOTS_DIR, f'{name}.sql')
        self.disconnect()
        db, user, host, port = DB_CONFIG['dbname'], DB_CONFIG['user'], DB_CONFIG['host'], str(DB_CONFIG['port'])
        
        for sql in [
            f"SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='{db}' AND pid<>pg_backend_pid()",
            f"DROP DATABASE IF EXISTS {db}",
            f"CREATE DATABASE {db}"
        ]:
            self._run_pg_cmd(['psql', '-h', host, '-p', port, '-U', user, '-d', 'postgres', '-c', sql])
        
        self._run_pg_cmd(['pg_restore', '-h', host, '-p', port, '-U', user, '-d', db, '-F', 'c', path])
        self.connect()
        print(f"✓ Snapshot restored: {name}")

    # ---- Table Hash Capture ----
    def capture_table_hashes(self, cur):
        """Captures MD5 hash of all tables to detect modifications"""
        hashes = {}
        for table in ALL_TABLES:
            try:
                # Uses checksum based on entire table content
                cur.execute(f"SELECT md5(CAST((array_agg(t.* ORDER BY 1)) AS text)) FROM {table} t")
                result = cur.fetchone()
                hashes[table] = result[0] if result else None
            except Exception as e:
                hashes[table] = f"ERROR: {e}"
        return hashes

    def compare_hashes(self, before, after):
        """Compares hashes and returns modified tables"""
        modified = set()
        for table in ALL_TABLES:
            if before.get(table) != after.get(table):
                modified.add(table)
        return modified

    def validate_modifications(self, tx_type, modified_tables):
        """Validates if modified tables are the expected ones"""
        expected = EXPECTED_MODIFICATIONS.get(tx_type, set())
        
        unexpected = modified_tables - expected  # Tables modified that shouldn't be
        missing = expected - modified_tables      # Tables that should be modified but weren't
        
        return {
            'expected': list(expected),
            'actual_modified': list(modified_tables),
            'unexpected_modifications': list(unexpected),
            'missing_modifications': list(missing),
            'is_valid': len(unexpected) == 0 and len(missing) == 0
        }

    # ---- Transaction Execution ----
    def execute(self, tx_type, params):
        """Executes any transaction by type"""
        func_name = self.func_names.get(tx_type)
        if not func_name:
            return {
                'success': False,
                'result': None,
                'db_state': None,
                'table_modifications': None,
                'error': f'Function not found for {tx_type}'
            }
        
        param_keys = TX_CONFIG[tx_type][1]
        param_values = [params[k] for k in param_keys]
        placeholders = ', '.join(['%s'] * len(param_values))
        
        with self.cursor() as cur:
            try:
                # Capture hash BEFORE execution
                hashes_before = self.capture_table_hashes(cur)
                
                # Execute function
                cur.execute(f"SELECT * FROM {func_name}({placeholders})", param_values)
                row = cur.fetchone()
                columns = [d[0] for d in cur.description]
                result = dict(zip(columns, row))
                
                # Capture transaction-specific state
                db_state = self.capture_state(tx_type, params, cur, result)
                
                # Capture hash AFTER execution
                hashes_after = self.capture_table_hashes(cur)
                
                # Compare and validate modifications
                modified_tables = self.compare_hashes(hashes_before, hashes_after)
                modification_validation = self.validate_modifications(tx_type, modified_tables)
                
                self.conn.commit()
                
                return {
                    'success': True, 
                    'result': result, 
                    'db_state': db_state,
                    'table_modifications': modification_validation,
                    'error': None
                }
            except Exception as e:
                self.conn.rollback()
                return {
                    'success': False, 
                    'result': None, 
                    'db_state': None,
                    'table_modifications': None,
                    'error': str(e)
                }

    # ---- State Capture ----
    def _query_dict(self, cur, sql, params):
        """Executes query and returns dict or None"""
        cur.execute(sql, params)
        row = cur.fetchone()
        return dict(zip([d[0] for d in cur.description], row)) if row else None

    def _query_list(self, cur, sql, params):
        """Executes query and returns list of dicts"""
        cur.execute(sql, params)
        cols = [d[0] for d in cur.description]
        return [dict(zip(cols, row)) for row in cur.fetchall()]
    

    def capture_state(self, tx_type, params, cur, result=None):
        """Captures database state after transaction"""
        state = {}
        w_id, d_id = params.get('in_w_id'), params.get('in_d_id')
        
        try:
            if tx_type == 'new_order':
                state['district'] = self._query_dict(cur,
                    "SELECT d_next_o_id, d_tax FROM bmsql_district WHERE d_w_id=%s AND d_id=%s", (w_id, d_id))
                if state['district']:
                    o_id = state['district']['d_next_o_id'] - 1
                    state['order'] = self._query_dict(cur,
                        "SELECT * FROM bmsql_oorder WHERE o_w_id=%s AND o_d_id=%s AND o_id=%s", (w_id, d_id, o_id))
                    state['new_order'] = self._query_dict(cur,
                        "SELECT * FROM bmsql_new_order WHERE no_w_id=%s AND no_d_id=%s AND no_o_id=%s", (w_id, d_id, o_id))
                    state['order_lines'] = self._query_list(cur,
                        "SELECT * FROM bmsql_order_line WHERE ol_w_id=%s AND ol_d_id=%s AND ol_o_id=%s ORDER BY ol_number", (w_id, d_id, o_id))
                    state['stock_records'] = []
                    for i_id, sw_id in zip(params.get('in_ol_i_id', []), params.get('in_ol_supply_w_id', [])):
                        if i_id:
                            rec = self._query_dict(cur,
                                "SELECT s_i_id, s_w_id, s_quantity, s_ytd, s_order_cnt, s_remote_cnt FROM bmsql_stock WHERE s_w_id=%s AND s_i_id=%s", (sw_id, i_id))
                            if rec:
                                state['stock_records'].append(rec)

            elif tx_type == 'payment':
                c_id = find_customer_id(result, params)

                c_w_id = params.get('in_c_w_id')
                c_d_id = params.get('in_c_d_id')
                
                state['customer'] = self._query_dict(cur,
                    "SELECT c_id, c_d_id, c_w_id, c_balance, c_ytd_payment, c_payment_cnt, c_data FROM bmsql_customer WHERE c_w_id=%s AND c_d_id=%s AND c_id=%s", 
                    (c_w_id, c_d_id, c_id))
                state['warehouse'] = self._query_dict(cur, 
                    "SELECT w_id, w_ytd FROM bmsql_warehouse WHERE w_id=%s", (w_id,))
                state['district'] = self._query_dict(cur, 
                    "SELECT d_id, d_w_id, d_ytd FROM bmsql_district WHERE d_w_id=%s AND d_id=%s", (w_id, d_id))
                state['history_record'] = self._query_dict(cur,
                    "SELECT * FROM bmsql_history WHERE h_c_w_id=%s AND h_c_d_id=%s AND h_c_id=%s ORDER BY h_date DESC LIMIT 1", 
                    (c_w_id, c_d_id, c_id))

            elif tx_type == 'order_status':
                # Read-only
                pass
                    
            elif tx_type == 'delivery':
                state['delivered_orders'] = []
                for d_loop in range(1, 11):
                    order = self._query_dict(cur, """
                        SELECT o.o_id, o.o_c_id, o.o_carrier_id,
                            (SELECT COUNT(*) FROM bmsql_new_order WHERE no_w_id=%s AND no_d_id=%s AND no_o_id=o.o_id) as still_new
                        FROM bmsql_oorder o WHERE o.o_w_id=%s AND o.o_d_id=%s ORDER BY o.o_id LIMIT 1
                    """, (w_id, d_loop, w_id, d_loop))
                    if order:
                        o_id, c_id = order['o_id'], order['o_c_id']
                        order['order_lines'] = self._query_list(cur,
                            "SELECT ol_number, ol_delivery_d, ol_amount FROM bmsql_order_line WHERE ol_w_id=%s AND ol_d_id=%s AND ol_o_id=%s", 
                            (w_id, d_loop, o_id))
                        order['customer'] = self._query_dict(cur,
                            "SELECT c_balance, c_delivery_cnt FROM bmsql_customer WHERE c_w_id=%s AND c_d_id=%s AND c_id=%s", 
                            (w_id, d_loop, c_id))
                        order['district_id'] = d_loop
                        state['delivered_orders'].append(order)

            elif tx_type == 'stock_level':
                # Read-only
                pass

        except Exception as e:
            state['capture_error'] = str(e)
        return state

    # ---- Save Results ----
    def save_results(self, tx_type, results):
        path = os.path.join(RESULTS_DIR, f'{tx_type}.json')
        with open(path, 'w') as f:
            json.dump({
                'transaction_type': tx_type, 
                'num_executions': len(results), 
                'executions': results
            }, f, indent=2, default=str)
        print(f"✓ Results saved: {path}")

def find_customer_id(result, params):
    """
    Procura o ID do cliente usando padrões flexíveis
    """
    if not result:
        return params.get('in_c_id')
    
    # Padrão: qualquer campo que termine com "c_id" (case insensitive)
    pattern = re.compile(r'.*c_id$', re.IGNORECASE)
    
    for key, value in result.items():
        if pattern.match(key) and value is not None:
            return value
    
    # Fallback
    return params.get('in_c_id')

def main():
    with open(PARAMS_FILE) as f:
        all_params = json.load(f)

    ex = TPCCExecutor()
    ex.connect()
    ex.install_functions()
    ex.create_snapshot('initial_state')

    for tx_type in TX_CONFIG:
        # Check if function was installed successfully
        if tx_type not in ex.func_names:
            print(f"\n⚠ Function {tx_type} not installed - SKIPPING")
            continue
            
        if tx_type not in all_params or not all_params[tx_type]:
            print(f"\n⚠ No parameters for {tx_type}")
            continue

        print(f"\n{'='*50}\nEXECUTING: {tx_type.upper()}\n{'='*50}")
        results = []
        for i, params in enumerate(all_params[tx_type], 1):
            print(f"  Execution {i}/{len(all_params[tx_type])}...", end=' ')
            
            try:
                result = ex.execute(tx_type, params)
                results.append({'execution_number': i, 'input_params': params, 'output': result})
                
                # Show result and modification validation
                if result['success']:
                    valid = result['table_modifications']['is_valid']
                    status = "✓" if valid else "⚠ UNEXPECTED MODIFICATIONS"
                    print(status)
                    if not valid:
                        mods = result['table_modifications']
                        if mods['unexpected_modifications']:
                            print(f"      Tables modified incorrectly: {mods['unexpected_modifications']}")
                        if mods['missing_modifications']:
                            print(f"      Tables not modified (should be): {mods['missing_modifications']}")
                else:
                    print(f"✗ {result['error']}")
            except Exception as e:
                print(f"✗ UNEXPECTED ERROR: {e}")
                results.append({
                    'execution_number': i,
                    'input_params': params,
                    'output': {
                        'success': False,
                        'result': None,
                        'db_state': None,
                        'table_modifications': None,
                        'error': f'Unexpected error: {str(e)}'
                    }
                })

        ex.save_results(tx_type, results)
        
        try:
            ex.restore_snapshot('initial_state')
        except Exception as e:
            print(f"⚠ Error restoring snapshot: {e}")

    ex.disconnect()
    print("\n✓ Process complete!")


if __name__ == '__main__':
    main()