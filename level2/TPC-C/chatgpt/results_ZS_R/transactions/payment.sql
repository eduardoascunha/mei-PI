CREATE OR REPLACE FUNCTION payment_transaction(
p_w_id integer,
p_d_id integer,
p_c_id integer,
p_c_d_id integer,
p_c_w_id integer,
p_c_last varchar,
p_h_amount numeric(6,2)
)
RETURNS TABLE(
out_c_id integer,
w_name varchar(10),
w_street_1 varchar(20),
w_street_2 varchar(20),
w_city varchar(20),
w_state char(2),
w_zip char(9),
d_name varchar(10),
d_street_1 varchar(20),
d_street_2 varchar(20),
d_city varchar(20),
d_state char(2),
d_zip char(9),
c_first varchar(16),
c_middle char(2),
c_street_1 varchar(20),
c_street_2 varchar(20),
c_city varchar(20),
c_state char(2),
c_zip char(9),
c_phone char(16),
c_since timestamp,
c_credit char(2),
c_credit_lim decimal(12,2),
c_discount decimal(4,4),
c_balance decimal(12,2),
c_data varchar(500),
h_date timestamp
)
LANGUAGE plpgsql
AS $$
DECLARE
v_w bmsql_warehouse%ROWTYPE;
v_d bmsql_district%ROWTYPE;
v_c bmsql_customer%ROWTYPE;
v_selected_c_id integer;
v_matching_ids integer[];
v_count integer;
v_index integer;
v_old_c_data varchar(500);
v_new_c_data varchar(500);
v_h_data varchar(24);
v_now timestamp := clock_timestamp();
BEGIN
-- 1) Select and update warehouse
SELECT w.* INTO v_w
FROM bmsql_warehouse w
WHERE w.w_id = p_w_id
FOR UPDATE;
IF NOT FOUND THEN
RAISE EXCEPTION 'Warehouse % not found', p_w_id;
END IF;


UPDATE bmsql_warehouse
SET w_ytd = v_w.w_ytd + p_h_amount
WHERE w_id = p_w_id;

-- 2) Select and update district
SELECT d.* INTO v_d
FROM bmsql_district d
WHERE d.d_w_id = p_w_id
  AND d.d_id = p_d_id
FOR UPDATE;
IF NOT FOUND THEN
    RAISE EXCEPTION 'District % for warehouse % not found', p_d_id, p_w_id;
END IF;

UPDATE bmsql_district
SET d_ytd = v_d.d_ytd + p_h_amount
WHERE d_w_id = p_w_id
  AND d_id = p_d_id;

-- 3) Determine customer selection mode
IF p_c_id IS NOT NULL AND p_c_id > 0 THEN
    -- Case 1: select by customer id
    SELECT c.* INTO v_c
    FROM bmsql_customer c
    WHERE c.c_w_id = p_c_w_id
      AND c.c_d_id = p_c_d_id
      AND c.c_id = p_c_id
    FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Customer id % in d % w % not found', p_c_id, p_c_d_id, p_c_w_id;
    END IF;
    v_selected_c_id := v_c.c_id;
ELSE
    -- Case 2: select by last name: find all matching customers sorted by first name
    SELECT array_agg(c.c_id ORDER BY c.c_first) INTO v_matching_ids
    FROM bmsql_customer c
    WHERE c.c_w_id = p_c_w_id
      AND c.c_d_id = p_c_d_id
      AND c.c_last = p_c_last;

    IF v_matching_ids IS NULL OR array_length(v_matching_ids,1) = 0 THEN
        RAISE EXCEPTION 'No customer with last name % in d % w %', p_c_last, p_c_d_id, p_c_w_id;
    END IF;

    v_count := array_length(v_matching_ids,1);
    v_index := CEIL(v_count::numeric / 2.0)::integer;
    v_selected_c_id := v_matching_ids[v_index];

    -- Now select the chosen customer FOR UPDATE
    SELECT c.* INTO v_c
    FROM bmsql_customer c
    WHERE c.c_w_id = p_c_w_id
      AND c.c_d_id = p_c_d_id
      AND c.c_id = v_selected_c_id
    FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Selected customer id % not found for update', v_selected_c_id;
    END IF;
END IF;

-- 4) Update customer financial fields and possibly c_data
v_old_c_data := COALESCE(v_c.c_data, '');

UPDATE bmsql_customer
SET c_balance = v_c.c_balance - p_h_amount,
    c_ytd_payment = COALESCE(v_c.c_ytd_payment,0) + p_h_amount,
    c_payment_cnt = COALESCE(v_c.c_payment_cnt,0) + 1
WHERE c_w_id = v_c.c_w_id
  AND c_d_id = v_c.c_d_id
  AND c_id = v_c.c_id;

-- If bad credit, prepend history info to c_data (left insert) and truncate to 500 chars
IF v_c.c_credit = 'BC' THEN
    -- build history info: format consistent and readable
    v_new_c_data := substring(
        (lpad(v_c.c_id::text,0,'') || v_c.c_id::text || ' ' ||
         v_c.c_d_id::text || ' ' ||
         v_c.c_w_id::text || ' ' ||
         p_d_id::text || ' ' ||
         p_w_id::text || ' ' ||
         to_char(p_h_amount,'FM9999990.00') || ' ' ||
         v_old_c_data)
        , 1, 500);

    UPDATE bmsql_customer
    SET c_data = v_new_c_data
    WHERE c_w_id = v_c.c_w_id
      AND c_d_id = v_c.c_d_id
      AND c_id = v_c.c_id;

    v_c.c_data := v_new_c_data;
ELSE
    -- For GC do not change c_data; return empty string as specified
    v_c.c_data := '';
END IF;

-- 5) Insert history row (H_DATA = W_NAME || 4 spaces || D_NAME)
v_h_data := COALESCE(v_w.w_name,'') || repeat(' ',4) || COALESCE(v_d.d_name,'');

INSERT INTO bmsql_history(
    h_c_id,
    h_c_d_id,
    h_c_w_id,
    h_d_id,
    h_w_id,
    h_date,
    h_amount,
    h_data
) VALUES (
    v_c.c_id,
    v_c.c_d_id,
    v_c.c_w_id,
    p_d_id,
    p_w_id,
    v_now,
    p_h_amount,
    LEFT(v_h_data,24)
);

-- 6) Re-fetch current customer values to return accurate fields (some were updated)
SELECT c.* INTO v_c
FROM bmsql_customer c
WHERE c.c_w_id = v_c.c_w_id
  AND c.c_d_id = v_c.c_d_id
  AND c.c_id = v_c.c_id;

-- Prepare output variables
out_c_id := v_c.c_id;
w_name := v_w.w_name;
w_street_1 := v_w.w_street_1;
w_street_2 := v_w.w_street_2;
w_city := v_w.w_city;
w_state := v_w.w_state;
w_zip := v_w.w_zip;
d_name := v_d.d_name;
d_street_1 := v_d.d_street_1;
d_street_2 := v_d.d_street_2;
d_city := v_d.d_city;
d_state := v_d.d_state;
d_zip := v_d.d_zip;
c_first := v_c.c_first;
c_middle := v_c.c_middle;
c_street_1 := v_c.c_street_1;
c_street_2 := v_c.c_street_2;
c_city := v_c.c_city;
c_state := v_c.c_state;
c_zip := v_c.c_zip;
c_phone := v_c.c_phone;
c_since := v_c.c_since;
c_credit := v_c.c_credit;
c_credit_lim := v_c.c_credit_lim;
c_discount := v_c.c_discount;
c_balance := v_c.c_balance;
-- c_data field: if credit was BC we already stored updated data; if GC ensure empty per spec
IF v_c.c_credit = 'BC' THEN
    c_data := substr(COALESCE(v_c.c_data,''),1,500);
ELSE
    c_data := '';
END IF;
h_date := v_now;

RETURN NEXT;
RETURN;


END;
$$;
