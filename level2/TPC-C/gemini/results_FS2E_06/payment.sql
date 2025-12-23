CREATE OR REPLACE FUNCTION payment(
    p_w_id integer,
    p_d_id integer,
    p_c_id integer,
    p_c_d_id integer,
    p_c_w_id integer,
    p_c_last varchar(16),
    p_h_amount decimal(6,2)
) RETURNS TABLE (
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
    c_id integer,
    c_first varchar(16),
    c_middle char(2),
    c_last varchar(16),
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
) AS $$
DECLARE
    v_c_id integer;
    v_h_data varchar(24);
    v_customer_count integer;
    v_customer_offset integer;
BEGIN
    -- Update warehouse and retrieve its info
    UPDATE bmsql_warehouse
    SET w_ytd = bmsql_warehouse.w_ytd + p_h_amount
    WHERE bmsql_warehouse.w_id = p_w_id
    RETURNING bmsql_warehouse.w_name, bmsql_warehouse.w_street_1, bmsql_warehouse.w_street_2, bmsql_warehouse.w_city, bmsql_warehouse.w_state, bmsql_warehouse.w_zip
    INTO w_name, w_street_1, w_street_2, w_city, w_state, w_zip;

    -- Update district and retrieve its info
    UPDATE bmsql_district
    SET d_ytd = bmsql_district.d_ytd + p_h_amount
    WHERE bmsql_district.d_w_id = p_w_id AND bmsql_district.d_id = p_d_id
    RETURNING bmsql_district.d_name, bmsql_district.d_street_1, bmsql_district.d_street_2, bmsql_district.d_city, bmsql_district.d_state, bmsql_district.d_zip
    INTO d_name, d_street_1, d_street_2, d_city, d_state, d_zip;

    -- Determine customer ID
    IF p_c_id IS NULL THEN
        SELECT count(*)
        INTO v_customer_count
        FROM bmsql_customer c
        WHERE c.c_w_id = p_c_w_id AND c.c_d_id = p_c_d_id AND c.c_last = p_c_last;

        v_customer_offset := (v_customer_count - 1) / 2;

        SELECT c.c_id
        INTO v_c_id
        FROM bmsql_customer c
        WHERE c.c_w_id = p_c_w_id AND c.c_d_id = p_c_d_id AND c.c_last = p_c_last
        ORDER BY c.c_first ASC
        LIMIT 1 OFFSET v_customer_offset;
    ELSE
        v_c_id := p_c_id;
    END IF;

    -- Update customer and retrieve their info
    UPDATE bmsql_customer
    SET
        c_balance = bmsql_customer.c_balance - p_h_amount,
        c_ytd_payment = bmsql_customer.c_ytd_payment + p_h_amount,
        c_payment_cnt = bmsql_customer.c_payment_cnt + 1,
        c_data = CASE
            WHEN bmsql_customer.c_credit = 'BC' THEN
                LEFT(v_c_id || ' ' || p_c_d_id || ' ' || p_c_w_id || ' ' || p_d_id || ' ' || p_w_id || ' ' || p_h_amount || ' | ' || bmsql_customer.c_data, 500)
            ELSE
                bmsql_customer.c_data
        END
    WHERE bmsql_customer.c_w_id = p_c_w_id AND bmsql_customer.c_d_id = p_c_d_id AND bmsql_customer.c_id = v_c_id
    RETURNING
        bmsql_customer.c_id, bmsql_customer.c_first, bmsql_customer.c_middle, bmsql_customer.c_last,
        bmsql_customer.c_street_1, bmsql_customer.c_street_2, bmsql_customer.c_city, bmsql_customer.c_state, bmsql_customer.c_zip,
        bmsql_customer.c_phone, bmsql_customer.c_since, bmsql_customer.c_credit, bmsql_customer.c_credit_lim,
        bmsql_customer.c_discount, bmsql_customer.c_balance,
        CASE WHEN bmsql_customer.c_credit = 'GC' THEN '' ELSE bmsql_customer.c_data END
    INTO
        c_id, c_first, c_middle, c_last,
        c_street_1, c_street_2, c_city, c_state, c_zip,
        c_phone, c_since, c_credit, c_credit_lim,
        c_discount, c_balance, c_data;

    -- Insert into history
    v_h_data := w_name || '    ' || d_name;
    h_date := now();

    INSERT INTO bmsql_history (h_c_id, h_c_d_id, h_c_w_id, h_d_id, h_w_id, h_date, h_amount, h_data)
    VALUES (v_c_id, p_c_d_id, p_c_w_id, p_d_id, p_w_id, h_date, p_h_amount, v_h_data);

    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;