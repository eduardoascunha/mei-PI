CREATE OR REPLACE FUNCTION payment (
    in_w_id integer,
    in_d_id integer,
    in_c_id integer,
    in_c_d_id integer,
    in_c_w_id integer,
    in_c_last varchar(16),
    in_h_amount decimal(6,2)
) RETURNS TABLE (
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
    out_c_last varchar(16),
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
    v_c_last_ret varchar(16);
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
    v_c_data varchar(500);
    v_new_c_data varchar(500);
    v_h_date timestamp := now();
    v_h_data varchar(24);
BEGIN
    UPDATE bmsql_warehouse
    SET w_ytd = w_ytd + in_h_amount
    WHERE w_id = in_w_id
    RETURNING w_name, w_street_1, w_street_2, w_city, w_state, w_zip
    INTO v_w_name, v_w_street_1, v_w_street_2, v_w_city, v_w_state, v_w_zip;

    UPDATE bmsql_district
    SET d_ytd = d_ytd + in_h_amount
    WHERE d_w_id = in_w_id AND d_id = in_d_id
    RETURNING d_name, d_street_1, d_street_2, d_city, d_state, d_zip
    INTO v_d_name, v_d_street_1, v_d_street_2, v_d_city, v_d_state, v_d_zip;

    IF in_c_id IS NOT NULL THEN
        v_c_id := in_c_id;
    ELSE
        DECLARE
            customer_count integer;
            target_offset integer;
        BEGIN
            SELECT count(*) INTO customer_count
            FROM bmsql_customer c
            WHERE c.c_w_id = in_c_w_id AND c.c_d_id = in_c_d_id AND c.c_last = in_c_last;

            target_offset := ceil(customer_count / 2.0) - 1;

            SELECT c.c_id INTO v_c_id
            FROM bmsql_customer c
            WHERE c.c_w_id = in_c_w_id AND c.c_d_id = in_c_d_id AND c.c_last = in_c_last
            ORDER BY c.c_first ASC
            LIMIT 1 OFFSET target_offset;
        END;
    END IF;

    SELECT c.c_first, c.c_middle, c.c_last, c.c_street_1, c.c_street_2, c.c_city, c.c_state, c.c_zip,
           c.c_phone, c.c_since, c.c_credit, c.c_credit_lim, c.c_discount, c.c_balance, c.c_data
    INTO v_c_first, v_c_middle, v_c_last_ret, v_c_street_1, v_c_street_2, v_c_city, v_c_state, v_c_zip,
         v_c_phone, v_c_since, v_c_credit, v_c_credit_lim, v_c_discount, v_c_balance, v_c_data
    FROM bmsql_customer c
    WHERE c.c_w_id = in_c_w_id AND c.c_d_id = in_c_d_id AND c.c_id = v_c_id;

    v_c_balance := v_c_balance - in_h_amount;

    IF v_c_credit = 'BC' THEN
        v_new_c_data := v_c_id || ' ' || in_c_d_id || ' ' || in_c_w_id || ' ' || in_d_id || ' ' || in_w_id || ' ' || in_h_amount::text || ' | ' || v_c_data;
        v_new_c_data := substr(v_new_c_data, 1, 500);

        UPDATE bmsql_customer
        SET c_balance = v_c_balance,
            c_ytd_payment = c_ytd_payment + in_h_amount,
            c_payment_cnt = c_payment_cnt + 1,
            c_data = v_new_c_data
        WHERE c_w_id = in_c_w_id AND c_d_id = in_c_d_id AND c_id = v_c_id;
        
        v_c_data := v_new_c_data;
    ELSE
        UPDATE bmsql_customer
        SET c_balance = v_c_balance,
            c_ytd_payment = c_ytd_payment + in_h_amount,
            c_payment_cnt = c_payment_cnt + 1
        WHERE c_w_id = in_c_w_id AND c_d_id = in_c_d_id AND c_id = v_c_id;
        
        v_c_data := '';
    END IF;

    v_h_data := v_w_name || '    ' || v_d_name;
    INSERT INTO bmsql_history (h_c_id, h_c_d_id, h_c_w_id, h_d_id, h_w_id, h_date, h_amount, h_data)
    VALUES (v_c_id, in_c_d_id, in_c_w_id, in_d_id, in_w_id, v_h_date, in_h_amount, v_h_data);

    RETURN QUERY SELECT
        v_c_id,
        v_w_name,
        v_w_street_1,
        v_w_street_2,
        v_w_city,
        v_w_state,
        v_w_zip,
        v_d_name,
        v_d_street_1,
        v_d_street_2,
        v_d_city,
        v_d_state,
        v_d_zip,
        v_c_first,
        v_c_middle,
        v_c_last_ret,
        v_c_street_1,
        v_c_street_2,
        v_c_city,
        v_c_state,
        v_c_zip,
        v_c_phone,
        v_c_since,
        v_c_credit,
        v_c_credit_lim,
        v_c_discount,
        v_c_balance,
        v_c_data,
        v_h_date;

END;
$$ LANGUAGE plpgsql;