CREATE OR REPLACE FUNCTION payment_transaction(
    p_w_id integer, 
    p_d_id integer, 
    p_c_id integer, 
    p_c_d_id integer, 
    p_c_w_id integer, 
    p_c_last varchar(16), 
    p_h_amount decimal(6,2)
)
RETURNS TABLE (
    c_id integer,
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
    v_c_data varchar(500);
    v_h_data varchar(24);
    v_h_date timestamp;
    v_c_id integer;
    v_c_row_count integer;
    v_c_rows record;
BEGIN
    v_h_date := now();

    UPDATE bmsql_warehouse 
    SET w_ytd = w_ytd + p_h_amount 
    WHERE w_id = p_w_id 
    RETURNING w_name, w_street_1, w_street_2, w_city, w_state, w_zip 
    INTO v_w_name, v_w_street_1, v_w_street_2, v_w_city, v_w_state, v_w_zip;

    UPDATE bmsql_district 
    SET d_ytd = d_ytd + p_h_amount 
    WHERE d_w_id = p_w_id AND d_id = p_d_id 
    RETURNING d_name, d_street_1, d_street_2, d_city, d_state, d_zip 
    INTO v_d_name, v_d_street_1, v_d_street_2, v_d_city, v_d_state, v_d_zip;

    IF p_c_last IS NULL THEN
        SELECT c_id, c_first, c_middle, c_last, c_street_1, c_street_2, c_city, c_state, c_zip, c_phone, c_since, c_credit, c_credit_lim, c_discount, c_balance, c_data 
        INTO v_c_id, v_c_first, v_c_middle, v_c_last, v_c_street_1, v_c_street_2, v_c_city, v_c_state, v_c_zip, v_c_phone, v_c_since, v_c_credit, v_c_credit_lim, v_c_discount, v_c_balance, v_c_data 
        FROM bmsql_customer 
        WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND c_id = p_c_id;

        UPDATE bmsql_customer 
        SET c_balance = c_balance - p_h_amount, c_ytd_payment = c_ytd_payment + p_h_amount, c_payment_cnt = c_payment_cnt + 1 
        WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND c_id = p_c_id;

        IF v_c_credit = 'BC' THEN
            UPDATE bmsql_customer 
            SET c_data = substring(v_c_data from 1 for 500 - length(concat(p_c_id, p_c_d_id, p_c_w_id, p_d_id, p_w_id, p_h_amount))) || concat(p_c_id, p_c_d_id, p_c_w_id, p_d_id, p_w_id, p_h_amount) 
            WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND c_id = p_c_id 
            RETURNING c_data INTO v_c_data;
        END IF;
    ELSE
        SELECT count(*) INTO v_c_row_count 
        FROM bmsql_customer 
        WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND c_last = p_c_last;

        FOR v_c_rows IN 
            SELECT c_id, c_first, c_middle, c_last, c_street_1, c_street_2, c_city, c_state, c_zip, c_phone, c_since, c_credit, c_credit_lim, c_discount, c_balance, c_data 
            FROM bmsql_customer 
            WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND c_last = p_c_last 
            ORDER BY c_first
        LOOP
            IF v_c_row_count / 2 + 1 = v_c_rows.row_number THEN
                v_c_id := v_c_rows.c_id;
                v_c_first := v_c_rows.c_first;
                v_c_middle := v_c_rows.c_middle;
                v_c_last := v_c_rows.c_last;
                v_c_street_1 := v_c_rows.c_street_1;
                v_c_street_2 := v_c_rows.c_street_2;
                v_c_city := v_c_rows.c_city;
                v_c_state := v_c_rows.c_state;
                v_c_zip := v_c_rows.c_zip;
                v_c_phone := v_c_rows.c_phone;
                v_c_since := v_c_rows.c_since;
                v_c_credit := v_c_rows.c_credit;
                v_c_credit_lim := v_c_rows.c_credit_lim;
                v_c_discount := v_c_rows.c_discount;
                v_c_balance := v_c_rows.c_balance;
                v_c_data := v_c_rows.c_data;
            END IF;
        END LOOP;

        UPDATE bmsql_customer 
        SET c_balance = c_balance - p_h_amount, c_ytd_payment = c_ytd_payment + p_h_amount, c_payment_cnt = c_payment_cnt + 1 
        WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND c_id = v_c_id;

        IF v_c_credit = 'BC' THEN
            UPDATE bmsql_customer 
            SET c_data = substring(v_c_data from 1 for 500 - length(concat(v_c_id, p_c_d_id, p_c_w_id, p_d_id, p_w_id, p_h_amount))) || concat(v_c_id, p_c_d_id, p_c_w_id, p_d_id, p_w_id, p_h_amount) 
            WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND c_id = v_c_id 
            RETURNING c_data INTO v_c_data;
        END IF;
    END IF;

    v_h_data := concat(v_w_name, '    ', v_d_name);

    INSERT INTO bmsql_history (h_c_id, h_c_d_id, h_c_w_id, h_d_id, h_w_id, h_date, h_amount, h_data) 
    VALUES (COALESCE(v_c_id, p_c_id), p_c_d_id, p_c_w_id, p_d_id, p_w_id, v_h_date, p_h_amount, v_h_data);

    RETURN QUERY 
    SELECT 
        COALESCE(v_c_id, p_c_id), 
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
        v_c_last, 
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
        v_c_balance - p_h_amount, 
        CASE WHEN v_c_credit = 'BC' THEN v_c_data ELSE '' END, 
        v_h_date;
END;
$$;