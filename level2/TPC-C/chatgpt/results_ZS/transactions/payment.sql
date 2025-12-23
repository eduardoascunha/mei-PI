CREATE OR REPLACE FUNCTION tpcc_payment(
p_w_id    integer,
p_d_id    integer,
p_c_id    integer,
p_c_d_id  integer,
p_c_w_id  integer,
p_c_last  varchar,
p_h_amount numeric(6,2)
)
RETURNS TABLE(
out_c_id integer,
out_w_name varchar(10),
out_w_street_1 varchar(20),
out_w_street_2 varchar(20),
out_w_city varchar(20),
out_w_state char(2),
out_w_zip char(9),
out_d_name varchar(10),
out_d_street_1 varchar(20),
out_d_street_2 varchar(20),
out_d_city varchar(20),
out_d_state char(2),
out_d_zip char(9),
out_c_first varchar(16),
out_c_middle char(2),
out_c_street_1 varchar(20),
out_c_street_2 varchar(20),
out_c_city varchar(20),
out_c_state char(2),
out_c_zip char(9),
out_c_phone char(16),
out_c_since timestamp,
out_c_credit char(2),
out_c_credit_lim decimal(12,2),
out_c_discount decimal(4,4),
out_c_balance decimal(12,2),
out_c_data varchar(500),
out_h_date timestamp
)
LANGUAGE plpgsql
AS $$
DECLARE
v_w_ytd numeric(12,2);
v_w_name varchar(10);
v_w_s1 varchar(20);
v_w_s2 varchar(20);
v_w_city varchar(20);
v_w_state char(2);
v_w_zip char(9);

v_d_ytd numeric(12,2);
v_d_name varchar(10);
v_d_s1 varchar(20);
v_d_s2 varchar(20);
v_d_city varchar(20);
v_d_state char(2);
v_d_zip char(9);

v_c_first varchar(16);
v_c_middle char(2);
v_c_last varchar(16);
v_c_street_1 varchar(20);
v_c_street_2 varchar(20);
v_c_city varchar(20);
v_c_state char(2);
v_c_zip char(9);
v_c_phone char(16);
v_c_since timestamp;
v_c_credit char(2);
v_c_credit_lim numeric(12,2);
v_c_discount numeric(4,4);
v_c_balance numeric(12,2);
v_c_ytd_payment numeric(12,2);
v_c_payment_cnt integer;
v_c_data varchar(500);

v_selected_c_id integer;
v_cnt integer;
v_offset integer;
v_new_c_data varchar(500);
v_h_data varchar(24);
v_now timestamp := current_timestamp;
BEGIN
-- 1) select and update warehouse
SELECT w.w_ytd, w.w_name, w.w_street_1, w.w_street_2, w.w_city, w.w_state, w.w_zip
INTO v_w_ytd, v_w_name, v_w_s1, v_w_s2, v_w_city, v_w_state, v_w_zip
FROM bmsql_warehouse w
WHERE w.w_id = p_w_id
FOR UPDATE;

IF NOT FOUND THEN
RAISE EXCEPTION 'Warehouse % not found', p_w_id;
END IF;

UPDATE bmsql_warehouse
SET w_ytd = v_w_ytd + p_h_amount
WHERE w_id = p_w_id;

-- 2) select and update district
SELECT d.d_ytd, d.d_name, d.d_street_1, d.d_street_2, d.d_city, d.d_state, d.d_zip
INTO v_d_ytd, v_d_name, v_d_s1, v_d_s2, v_d_city, v_d_state, v_d_zip
FROM bmsql_district d
WHERE d.d_w_id = p_w_id AND d.d_id = p_d_id
FOR UPDATE;

IF NOT FOUND THEN
RAISE EXCEPTION 'District % for warehouse % not found', p_d_id, p_w_id;
END IF;

UPDATE bmsql_district
SET d_ytd = v_d_ytd + p_h_amount
WHERE d_w_id = p_w_id AND d_id = p_d_id;

-- 3) select customer by id or by last name (median)
IF p_c_id IS NOT NULL AND p_c_id > 0 AND (p_c_last IS NULL OR trim(p_c_last) = '') THEN
-- select by customer number
SELECT c.c_id, c.c_first, c.c_middle, c.c_last, c.c_street_1, c.c_street_2, c.c_city, c.c_state, c.c_zip,
c.c_phone, c.c_since, c.c_credit, c.c_credit_lim, c.c_discount, c.c_balance, c.c_ytd_payment, c.c_payment_cnt, c.c_data
INTO v_selected_c_id, v_c_first, v_c_middle, v_c_last, v_c_street_1, v_c_street_2, v_c_city, v_c_state, v_c_zip,
v_c_phone, v_c_since, v_c_credit, v_c_credit_lim, v_c_discount, v_c_balance, v_c_ytd_payment, v_c_payment_cnt, v_c_data
FROM bmsql_customer c
WHERE c.c_w_id = p_c_w_id AND c.c_d_id = p_c_d_id AND c.c_id = p_c_id
FOR UPDATE;


IF NOT FOUND THEN
  RAISE EXCEPTION 'Customer id % not found in warehouse % district %', p_c_id, p_c_w_id, p_c_d_id;
END IF;


ELSE
-- select by last name: median-of-sorted-by-first
SELECT count(*) INTO v_cnt
FROM bmsql_customer c
WHERE c.c_w_id = p_c_w_id AND c.c_d_id = p_c_d_id AND c.c_last = p_c_last;


IF v_cnt = 0 THEN
  RAISE EXCEPTION 'No customer with last name % in warehouse % district %', p_c_last, p_c_w_id, p_c_d_id;
END IF;

v_offset := (v_cnt - 1) / 2; -- integer division yields floor((cnt-1)/2) which equals ceil(cnt/2)-1

-- select the median row (ordered by c_first ascending)
SELECT c.c_id, c.c_first, c.c_middle, c.c_last, c.c_street_1, c.c_street_2, c.c_city, c.c_state, c.c_zip,
       c.c_phone, c.c_since, c.c_credit, c.c_credit_lim, c.c_discount, c.c_balance, c.c_ytd_payment, c.c_payment_cnt, c.c_data
  INTO v_selected_c_id, v_c_first, v_c_middle, v_c_last, v_c_street_1, v_c_street_2, v_c_city, v_c_state, v_c_zip,
       v_c_phone, v_c_since, v_c_credit, v_c_credit_lim, v_c_discount, v_c_balance, v_c_ytd_payment, v_c_payment_cnt, v_c_data
FROM bmsql_customer c
WHERE c.c_w_id = p_c_w_id AND c.c_d_id = p_c_d_id AND c.c_last = p_c_last
ORDER BY c.c_first ASC
OFFSET v_offset LIMIT 1
FOR UPDATE;

IF NOT FOUND THEN
  RAISE EXCEPTION 'Unable to select median customer for last name %', p_c_last;
END IF;


END IF;

-- 4) update customer monetary fields
v_c_balance := v_c_balance - p_h_amount;
v_c_ytd_payment := COALESCE(v_c_ytd_payment,0) + p_h_amount;
v_c_payment_cnt := COALESCE(v_c_payment_cnt,0) + 1;

-- 5) if bad credit, prepend history info to c_data and truncate to 500
IF v_c_credit = 'BC' THEN
-- format: C_ID, C_D_ID, C_W_ID, D_ID, W_ID, H_AMOUNT  (separated and followed by a " | " as delimiter)
v_new_c_data := left( (format('%s %s %s %s %s %.2f | ', v_selected_c_id, p_c_d_id, p_c_w_id, p_d_id, p_w_id, p_h_amount) || coalesce(v_c_data,'')), 500);
ELSE
v_new_c_data := v_c_data; -- unchanged for GC
END IF;

UPDATE bmsql_customer
SET c_balance = v_c_balance,
c_ytd_payment = v_c_ytd_payment,
c_payment_cnt = v_c_payment_cnt,
c_data = v_new_c_data
WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND c_id = v_selected_c_id;

-- 6) build h_data and insert history row
v_h_data := left( coalesce(v_w_name,'') || '    ' || coalesce(v_d_name,''), 24);

INSERT INTO bmsql_history(h_c_id, h_c_d_id, h_c_w_id, h_d_id, h_w_id, h_date, h_amount, h_data)
VALUES (v_selected_c_id, p_c_d_id, p_c_w_id, p_d_id, p_w_id, v_now, p_h_amount, v_h_data);

-- 7) prepare output fields and return
out_c_id := v_selected_c_id;
out_w_name := v_w_name;
out_w_street_1 := v_w_s1;
out_w_street_2 := v_w_s2;
out_w_city := v_w_city;
out_w_state := v_w_state;
out_w_zip := v_w_zip;

out_d_name := v_d_name;
out_d_street_1 := v_d_s1;
out_d_street_2 := v_d_s2;
out_d_city := v_d_city;
out_d_state := v_d_state;
out_d_zip := v_d_zip;

out_c_first := v_c_first;
out_c_middle := v_c_middle;
out_c_street_1 := v_c_street_1;
out_c_street_2 := v_c_street_2;
out_c_city := v_c_city;
out_c_state := v_c_state;
out_c_zip := v_c_zip;
out_c_phone := v_c_phone;
out_c_since := v_c_since;
out_c_credit := v_c_credit;
out_c_credit_lim := v_c_credit_lim;
out_c_discount := v_c_discount;
out_c_balance := v_c_balance;
out_c_data := CASE WHEN v_c_credit = 'BC' THEN left(v_new_c_data,500) ELSE '' END;
out_h_date := v_now;

RETURN NEXT;
RETURN;
EXCEPTION
WHEN others THEN
-- rethrow with detail
RAISE;
END;
$$;
