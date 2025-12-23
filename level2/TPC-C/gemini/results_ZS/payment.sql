CREATE OR REPLACE FUNCTION payment (
    in_w_id integer,
    in_d_id integer,
    in_c_w_id integer,
    in_c_d_id integer,
    in_c_id integer,
    in_c_last varchar(16),
    in_h_amount decimal(6,2),
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
    OUT out_c_id integer,
    OUT out_c_first varchar(16),
    OUT out_c_middle char(2),
    OUT out_c_last varchar(16),
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
) RETURNS record AS $$
DECLARE
    v_c_id integer;
    v_h_data varchar(24);
    v_c_data_to_prepend varchar(200);
    customer_curs refcursor;
    customer_count integer;
    customer_idx integer;
BEGIN
    UPDATE bmsql_warehouse
    SET w_ytd = w_ytd + in_h_amount
    WHERE w_id = in_w_id
    RETURNING w_name, w_street_1, w_street_2, w_city, w_state, w_zip
    INTO out_w_name, out_w_street_1, out_w_street_2, out_w_city, out_w_state, out_w_zip;

    UPDATE bmsql_district
    SET d_ytd = d_ytd + in_h_amount
    WHERE d_w_id = in_w_id AND d_id = in_d_id
    RETURNING d_name, d_street_1, d_street_2, d_city, d_state, d_zip
    INTO out_d_name, out_d_street_1, out_d_street_2, out_d_city, out_d_state, out_d_zip;

    IF in_c_id IS NULL THEN
        SELECT count(*) INTO customer_count
        FROM bmsql_customer AS c
        WHERE c.c_w_id = in_c_w_id AND c.c_d_id = in_c_d_id AND c.c_last = in_c_last;

        OPEN customer_curs FOR
            SELECT c.c_id FROM bmsql_customer AS c
            WHERE c.c_w_id = in_c_w_id AND c.c_d_id = in_c_d_id AND c.c_last = in_c_last
            ORDER BY c.c_first;

        FOR customer_idx IN 1..((customer_count + 1) / 2) LOOP
            FETCH customer_curs INTO v_c_id;
        END LOOP;

        CLOSE customer_curs;
    ELSE
        v_c_id := in_c_id;
    END IF;

    v_c_data_to_prepend := v_c_id::text || ' ' || in_c_d_id::text || ' ' || in_c_w_id::text || ' ' || in_d_id::text || ' ' || in_w_id::text || ' ' || in_h_amount::text || ' | ';

    UPDATE bmsql_customer
    SET
        c_balance = c_balance - in_h_amount,
        c_ytd_payment = c_ytd_payment + in_h_amount,
        c_payment_cnt = c_payment_cnt + 1,
        c_data = CASE
            WHEN c_credit = 'BC' THEN substr(v_c_data_to_prepend || c_data, 1, 500)
            ELSE c_data
        END
    WHERE c_w_id = in_c_w_id AND c_d_id = in_c_d_id AND c_id = v_c_id
    RETURNING
        c_id, c_first, c_middle, c_last, c_street_1, c_street_2, c_city, c_state, c_zip,
        c_phone, c_since, c_credit, c_credit_lim, c_discount, c_balance, c_data
    INTO
        out_c_id, out_c_first, out_c_middle, out_c_last, out_c_street_1, out_c_street_2, out_c_city, out_c_state, out_c_zip,
        out_c_phone, out_c_since, out_c_credit, out_c_credit_lim, out_c_discount, out_c_balance, out_c_data;

    IF out_c_credit = 'GC' THEN
        out_c_data := '';
    END IF;

    v_h_data := out_w_name || '    ' || out_d_name;
    out_h_date := now();

    INSERT INTO bmsql_history (h_c_id, h_c_d_id, h_c_w_id, h_d_id, h_w_id, h_date, h_amount, h_data)
    VALUES (out_c_id, in_c_d_id, in_c_w_id, in_d_id, in_w_id, out_h_date, in_h_amount, v_h_data);

END;
$$ LANGUAGE plpgsql;