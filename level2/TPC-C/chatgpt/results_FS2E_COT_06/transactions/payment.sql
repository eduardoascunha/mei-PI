CREATE OR REPLACE FUNCTION bmsql_proc_payment(
in_w_id integer,
in_d_id integer,
in_c_id integer,
in_c_d_id integer,
in_c_w_id integer,
in_c_last varchar(16),
in_h_amount decimal(6,2)
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
) AS
$$
DECLARE
v_w_rec RECORD;
v_d_rec RECORD;
v_c_rec RECORD;
v_selected_c_id integer;
v_count integer;
v_offset integer;
v_history_entry text;
v_h_data text;
v_new_c_data text;
BEGIN
-- 1) Update warehouse w_ytd and retrieve warehouse address/info
UPDATE bmsql_warehouse w
SET w_ytd = COALESCE(w.w_ytd,0) + in_h_amount
WHERE w.w_id = in_w_id
RETURNING w.w_name, w.w_street_1, w.w_street_2, w.w_city, w.w_state, w.w_zip
INTO v_w_rec;
IF NOT FOUND THEN
RAISE EXCEPTION 'Warehouse % not found', in_w_id;
END IF;


-- 2) Update district d_ytd and retrieve district address/info
UPDATE bmsql_district d
SET d_ytd = COALESCE(d.d_ytd,0) + in_h_amount
WHERE d.d_w_id = in_w_id AND d.d_id = in_d_id
RETURNING d.d_name, d.d_street_1, d.d_street_2, d.d_city, d.d_state, d.d_zip
INTO v_d_rec;
IF NOT FOUND THEN
    RAISE EXCEPTION 'District % for warehouse % not found', in_d_id, in_w_id;
END IF;

-- 3) Determine customer: by id if provided (non-null and >0), otherwise by last name selection
IF in_c_id IS NULL OR in_c_id = 0 THEN
    -- select by last name from the customer warehouse/district indicated by in_c_w_id/in_c_d_id
    SELECT count(*) INTO v_count
    FROM bmsql_customer c
    WHERE c.c_w_id = in_c_w_id AND c.c_d_id = in_c_d_id AND c.c_last = in_c_last;

    IF v_count = 0 THEN
        RAISE EXCEPTION 'No customer with last name % in W % D %', in_c_last, in_c_w_id, in_c_d_id;
    END IF;

    v_offset := FLOOR((v_count - 1) / 2.0)::integer; -- position n/2 rounded up -> zero-based offset
    SELECT c.c_id INTO v_selected_c_id
    FROM bmsql_customer c
    WHERE c.c_w_id = in_c_w_id AND c.c_d_id = in_c_d_id AND c.c_last = in_c_last
    ORDER BY c.c_first ASC
    LIMIT 1 OFFSET v_offset;
ELSE
    v_selected_c_id := in_c_id;
END IF;

-- 4) Lock the selected customer row FOR UPDATE and retrieve required fields
SELECT c.c_id, c.c_first, c.c_middle, c.c_street_1, c.c_street_2, c.c_city, c.c_state, c.c_zip,
       c.c_phone, c.c_since, c.c_credit, c.c_credit_lim, c.c_discount, c.c_balance, c.c_data
INTO v_c_rec
FROM bmsql_customer c
WHERE c.c_w_id = in_c_w_id AND c.c_d_id = in_c_d_id AND c.c_id = v_selected_c_id
FOR UPDATE;

IF NOT FOUND THEN
    RAISE EXCEPTION 'Customer % in W % D % not found', v_selected_c_id, in_c_w_id, in_c_d_id;
END IF;

-- 5) Update customer financials
v_new_c_data := coalesce(v_c_rec.c_data,'');
IF v_c_rec.c_credit = 'BC' THEN
    -- build history entry to prepend (human readable)
    v_history_entry := format('%s %s %s %s %s %s | ',
                              v_c_rec.c_id::text,
                              in_c_d_id::text,
                              in_c_w_id::text,
                              in_d_id::text,
                              in_w_id::text,
                              to_char(in_h_amount,'FM9999990.00'));
    v_new_c_data := substr(v_history_entry || v_new_c_data, 1, 500);
END IF;

UPDATE bmsql_customer c
SET c_balance = COALESCE(c.c_balance,0) - in_h_amount,
    c_ytd_payment = COALESCE(c.c_ytd_payment,0) + in_h_amount,
    c_payment_cnt = COALESCE(c.c_payment_cnt,0) + 1,
    c_data = CASE WHEN v_c_rec.c_credit = 'BC' THEN v_new_c_data ELSE c.c_data END
WHERE c.c_w_id = in_c_w_id AND c.c_d_id = in_c_d_id AND c.c_id = v_selected_c_id;

-- 6) Build history h_data and insert history row
v_h_data := COALESCE(v_w_rec.w_name,'') || '    ' || COALESCE(v_d_rec.d_name,'');
INSERT INTO bmsql_history(h_c_id, h_c_d_id, h_c_w_id, h_d_id, h_w_id, h_date, h_amount, h_data)
VALUES (v_selected_c_id, in_c_d_id, in_c_w_id, in_d_id, in_w_id, now(), in_h_amount, v_h_data);

-- 7) Prepare output values
out_c_id := v_selected_c_id;
out_w_name := v_w_rec.w_name;
out_w_street_1 := v_w_rec.w_street_1;
out_w_street_2 := v_w_rec.w_street_2;
out_w_city := v_w_rec.w_city;
out_w_state := v_w_rec.w_state;
out_w_zip := v_w_rec.w_zip;

out_d_name := v_d_rec.d_name;
out_d_street_1 := v_d_rec.d_street_1;
out_d_street_2 := v_d_rec.d_street_2;
out_d_city := v_d_rec.d_city;
out_d_state := v_d_rec.d_state;
out_d_zip := v_d_rec.d_zip;

out_c_first := v_c_rec.c_first;
out_c_middle := v_c_rec.c_middle;
out_c_street_1 := v_c_rec.c_street_1;
out_c_street_2 := v_c_rec.c_street_2;
out_c_city := v_c_rec.c_city;
out_c_state := v_c_rec.c_state;
out_c_zip := v_c_rec.c_zip;
out_c_phone := v_c_rec.c_phone;
out_c_since := v_c_rec.c_since;
out_c_credit := v_c_rec.c_credit;
out_c_credit_lim := v_c_rec.c_credit_lim;
out_c_discount := v_c_rec.c_discount;

-- refresh balance and c_data from table to reflect updates (in case of triggers or defaults)
SELECT c.c_balance, c.c_data INTO out_c_balance, out_c_data
FROM bmsql_customer c
WHERE c.c_w_id = in_c_w_id AND c.c_d_id = in_c_d_id AND c.c_id = v_selected_c_id;

-- Only return first 200 characters of c_data when credit = 'BC', else empty string
IF out_c_credit = 'BC' THEN
    out_c_data := substr(out_c_data::text, 1, 200);
ELSE
    out_c_data := '';
END IF;

out_h_date := (SELECT h_date FROM bmsql_history WHERE h_c_id = v_selected_c_id AND h_c_d_id = in_c_d_id AND h_c_w_id = in_c_w_id ORDER BY h_date DESC LIMIT 1);

RETURN NEXT;
RETURN;


END;
$$
LANGUAGE plpgsql;
