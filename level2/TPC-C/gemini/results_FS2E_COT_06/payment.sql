CREATE OR REPLACE FUNCTION bmsql_proc_payment(
    w_id_in integer,
    d_id_in integer,
    c_id_in integer,
    c_d_id_in integer,
    c_w_id_in integer,
    c_last_in varchar(16),
    h_amount_in decimal(6,2)
)
RETURNS TABLE (
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
    v_w_name varchar(10);
    v_w_street_1 varchar(20);
    v_w_street_2 varchar(20);
    v_w_city varchar(20);
    v_w_state char(2);
    v_w_zip char(9);
    v_d_name varchar(10);
    v_d_street_1 varchar(20);
    v_d_street_2 varchar(20);
    v_d_city varchar(20);
    v_d_state char(2);
    v_d_zip char(9);
    v_c_id integer;
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
    v_c_credit_lim decimal(12,2);
    v_c_discount decimal(4,4);
    v_c_balance decimal(12,2);
    v_c_data_in varchar(500);
    v_c_data_out varchar(500);
    v_h_date timestamp;
    v_h_data varchar(24);
    customer_count integer;
BEGIN
    UPDATE bmsql_warehouse
    SET w_ytd = w_ytd + h_amount_in
    WHERE w_id = w_id_in
    RETURNING bmsql_warehouse.w_name, bmsql_warehouse.w_street_1, bmsql_warehouse.w_street_2, bmsql_warehouse.w_city, bmsql_warehouse.w_state, bmsql_warehouse.w_zip
    INTO v_w_name, v_w_street_1, v_w_street_2, v_w_city, v_w_state, v_w_zip;

    UPDATE bmsql_district
    SET d_ytd = d_ytd + h_amount_in
    WHERE d_w_id = w_id_in AND d_id = d_id_in
    RETURNING bmsql_district.d_name, bmsql_district.d_street_1, bmsql_district.d_street_2, bmsql_district.d_city, bmsql_district.d_state, bmsql_district.d_zip
    INTO v_d_name, v_d_street_1, v_d_street_2, v_d_city, v_d_state, v_d_zip;

    IF c_id_in IS NULL THEN
        SELECT count(*) INTO customer_count
        FROM bmsql_customer c
        WHERE c.c_w_id = c_w_id_in AND c.c_d_id = c_d_id_in AND c.c_last = c_last_in;

        SELECT c.c_id INTO v_c_id
        FROM bmsql_customer c
        WHERE c.c_w_id = c_w_id_in AND c.c_d_id = c_d_id_in AND c.c_last = c_last_in
        ORDER BY c.c_first
        OFFSET ceil(customer_count / 2.0) - 1
        LIMIT 1;
    ELSE
        v_c_id := c_id_in;
    END IF;

    SELECT
        c.c_first, c.c_middle, c.c_last, c.c_street_1, c.c_street_2, c.c_city, c.c_state, c.c_zip,
        c.c_phone, c.c_since, c.c_credit, c.c_credit_lim, c.c_discount, c.c_balance, c.c_data
    INTO
        v_c_first, v_c_middle, v_c_last, v_c_street_1, v_c_street_2, v_c_city, v_c_state, v_c_zip,
        v_c_phone, v_c_since, v_c_credit, v_c_credit_lim, v_c_discount, v_c_balance, v_c_data_in
    FROM bmsql_customer c
    WHERE c.c_w_id = c_w_id_in AND c.c_d_id = c_d_id_in AND c.c_id = v_c_id
    FOR UPDATE;

    v_c_balance := v_c_balance - h_amount_in;

    IF v_c_credit = 'BC' THEN
        v_c_data_out := v_c_id || ' ' || c_d_id_in || ' ' || c_w_id_in || ' ' || d_id_in || ' ' || w_id_in || ' ' || h_amount_in || ' | ' || v_c_data_in;
        v_c_data_out := substr(v_c_data_out, 1, 500);

        UPDATE bmsql_customer c
        SET c_balance = v_c_balance,
            c_ytd_payment = c.c_ytd_payment + h_amount_in,
            c_payment_cnt = c.c_payment_cnt + 1,
            c_data = v_c_data_out
        WHERE c.c_w_id = c_w_id_in AND c.c_d_id = c_d_id_in AND c.c_id = v_c_id;
    ELSE
        v_c_data_out := '';
        UPDATE bmsql_customer c
        SET c_balance = v_c_balance,
            c_ytd_payment = c.c_ytd_payment + h_amount_in,
            c_payment_cnt = c.c_payment_cnt + 1
        WHERE c.c_w_id = c_w_id_in AND c.c_d_id = c_d_id_in AND c.c_id = v_c_id;
    END IF;

    v_h_data := v_w_name || '    ' || v_d_name;
    v_h_date := NOW();

    INSERT INTO bmsql_history (h_c_id, h_c_d_id, h_c_w_id, h_d_id, h_w_id, h_date, h_amount, h_data)
    VALUES (v_c_id, c_d_id_in, c_w_id_in, d_id_in, w_id_in, v_h_date, h_amount_in, v_h_data);

    RETURN QUERY SELECT
        v_w_name, v_w_street_1, v_w_street_2, v_w_city, v_w_state, v_w_zip,
        v_d_name, v_d_street_1, v_d_street_2, v_d_city, v_d_state, v_d_zip,
        v_c_id, v_c_first, v_c_middle, v_c_last, v_c_street_1, v_c_street_2,
        v_c_city, v_c_state, v_c_zip, v_c_phone, v_c_since, v_c_credit,
        v_c_credit_lim, v_c_discount, v_c_balance, v_c_data_out, v_h_date;
END;
$$ LANGUAGE plpgsql;