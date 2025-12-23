CREATE OR REPLACE FUNCTION bmsql_proc_payment(
IN in_w_id integer,
IN in_d_id integer,
INOUT in_c_id integer,
IN in_c_d_id integer,
IN in_c_w_id integer,
IN in_c_last varchar(16),
IN in_h_amount decimal(6,2),
OUT out_c_id integer,
OUT out_w_name varchar(10),
OUT out_w_street_1 varchar(20),
OUT out_w_street_2 varchar(20),
OUT out_w_city varchar(20),
OUT out_w_state char(2),
OUT out_w_zip char(9),
OUT out_d_name varchar(10),
OUT out_d_street_1 varchar(20),
OUT out_d_street_2 varchar(20),
OUT out_d_city varchar(20),
OUT out_d_state char(2),
OUT out_d_zip char(9),
OUT out_c_first varchar(16),
OUT out_c_middle char(2),
OUT out_c_street_1 varchar(20),
OUT out_c_street_2 varchar(20),
OUT out_c_city varchar(20),
OUT out_c_state char(2),
OUT out_c_zip char(9),
OUT out_c_phone char(16),
OUT out_c_since timestamp,
OUT out_c_credit char(2),
OUT out_c_credit_lim decimal(12,2),
OUT out_c_discount decimal(4,4),
OUT out_c_balance decimal(12,2),
OUT out_c_data varchar(500),
OUT out_h_date timestamp
) AS
$$
DECLARE
v_cnt integer;
v_offset integer;
v_old_c_data varchar(500);
v_new_entry varchar(500);
v_concatted varchar(1000);
v_h_data varchar(24);
BEGIN
-- Determine customer id when last name provided
IF in_c_last IS NOT NULL THEN
SELECT count(*) INTO v_cnt
FROM bmsql_customer c
WHERE c.c_w_id = in_c_w_id AND c.c_d_id = in_c_d_id AND c.c_last = in_c_last;
IF v_cnt = 0 THEN
RAISE EXCEPTION 'Customer with last name % not found in warehouse % district %', in_c_last, in_c_w_id, in_c_d_id;
END IF;
v_offset := (v_cnt - 1) / 2; -- integer division gives floor((n-1)/2) which is ceil(n/2)-1
SELECT c.c_id INTO in_c_id
FROM bmsql_customer c
WHERE c.c_w_id = in_c_w_id AND c.c_d_id = in_c_d_id AND c.c_last = in_c_last
ORDER BY c.c_first ASC
OFFSET v_offset LIMIT 1;
END IF;


-- Set out_c_id
out_c_id := in_c_id;

-- Read and update WAREHOUSE: return address fields and increment w_ytd
UPDATE bmsql_warehouse w
   SET w_ytd = COALESCE(w.w_ytd,0) + in_h_amount
 WHERE w.w_id = in_w_id
 RETURNING w.w_name, w.w_street_1, w.w_street_2, w.w_city, w.w_state, w.w_zip
 INTO out_w_name, out_w_street_1, out_w_street_2, out_w_city, out_w_state, out_w_zip;
IF NOT FOUND THEN
    RAISE EXCEPTION 'Warehouse % not found', in_w_id;
END IF;

-- Read and update DISTRICT: return address fields and increment d_ytd
UPDATE bmsql_district d
   SET d_ytd = COALESCE(d.d_ytd,0) + in_h_amount
 WHERE d.d_w_id = in_w_id AND d.d_id = in_d_id
 RETURNING d.d_name, d.d_street_1, d.d_street_2, d.d_city, d.d_state, d.d_zip
 INTO out_d_name, out_d_street_1, out_d_street_2, out_d_city, out_d_state, out_d_zip;
IF NOT FOUND THEN
    RAISE EXCEPTION 'District % for warehouse % not found', in_d_id, in_w_id;
END IF;

-- Select customer current data (must use the customer's warehouse/district passed in inputs)
SELECT c.c_first, c.c_middle, c.c_street_1, c.c_street_2, c.c_city, c.c_state, c.c_zip,
       c.c_phone, c.c_since, c.c_credit, c.c_credit_lim, c.c_discount, c.c_balance, c.c_data
  INTO out_c_first, out_c_middle, out_c_street_1, out_c_street_2, out_c_city, out_c_state, out_c_zip,
       out_c_phone, out_c_since, out_c_credit, out_c_credit_lim, out_c_discount, out_c_balance, v_old_c_data
  FROM bmsql_customer c
 WHERE c.c_w_id = in_c_w_id AND c.c_d_id = in_c_d_id AND c.c_id = in_c_id
 FOR UPDATE;
IF NOT FOUND THEN
    RAISE EXCEPTION 'Customer % not found in warehouse % district %', in_c_id, in_c_w_id, in_c_d_id;
END IF;

-- Update customer financials
UPDATE bmsql_customer c
   SET c_balance = c.c_balance - in_h_amount,
       c_ytd_payment = COALESCE(c.c_ytd_payment,0) + in_h_amount,
       c_payment_cnt = COALESCE(c.c_payment_cnt,0) + 1
 WHERE c.c_w_id = in_c_w_id AND c.c_d_id = in_c_d_id AND c.c_id = in_c_id;

-- Refresh the balance we'll return
SELECT c.c_balance, c.c_data
  INTO out_c_balance, v_old_c_data
  FROM bmsql_customer c
 WHERE c.c_w_id = in_c_w_id AND c.c_d_id = in_c_d_id AND c.c_id = in_c_id;

-- Handle credit data update for Bad Credit ("BC")
IF out_c_credit = 'BC' THEN
    -- Build history entry: format "C_ID C_D_ID C_W_ID D_ID W_ID H_AMOUNT | " (kept compact)
    v_new_entry := lpad(in_c_id::text,0,'') ||
                   in_c_id::text || ',' ||
                   in_c_d_id::text || ',' ||
                   in_c_w_id::text || ',' ||
                   in_d_id::text || ',' ||
                   in_w_id::text || ',' ||
                   trim(to_char(in_h_amount,'FM999990.00')) || ' ';
    -- Prepend the new entry to existing c_data and truncate to 500 chars
    v_concatted := v_new_entry || COALESCE(v_old_c_data,'');
    out_c_data := substring(v_concatted from 1 for 500);
    -- Update customer's c_data with the truncated new string
    UPDATE bmsql_customer c
       SET c_data = out_c_data
     WHERE c.c_w_id = in_c_w_id AND c.c_d_id = in_c_d_id AND c.c_id = in_c_id;
ELSE
    -- For good credit, do not modify c_data and return empty string for output c_data per spec
    out_c_data := '';
END IF;

-- Build H_DATE and H_DATA and insert history row
out_h_date := clock_timestamp();
v_h_data := out_w_name || '    ' || out_d_name; -- W_NAME + 4 spaces + D_NAME

INSERT INTO bmsql_history(h_c_id, h_c_d_id, h_c_w_id, h_d_id, h_w_id, h_date, h_amount, h_data)
VALUES (in_c_id, in_c_d_id, in_c_w_id, in_d_id, in_w_id, out_h_date, in_h_amount, substring(v_h_data from 1 for 24));

-- Return customer id (mirror)
out_c_id := in_c_id;

RETURN;


END;
$$
LANGUAGE plpgsql;
