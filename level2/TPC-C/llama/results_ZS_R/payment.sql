CREATE OR REPLACE FUNCTION payment(
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
)
LANGUAGE plpgsql
AS $$
DECLARE 
    v_c_id integer;
    v_c_row_count integer;
    v_h_data varchar(24);
    v_c_data_new varchar(500);
BEGIN
    -- Update warehouse
    UPDATE bmsql_warehouse 
    SET w_ytd = w_ytd + p_h_amount 
    WHERE w_id = p_w_id 
    RETURNING w_name, w_street_1, w_street_2, w_city, w_state, w_zip 
    INTO w_name, w_street_1, w_street_2, w_city, w_state, w_zip;

    -- Update district
    UPDATE bmsql_district 
    SET d_ytd = d_ytd + p_h_amount 
    WHERE d_w_id = p_w_id AND d_id = p_d_id 
    RETURNING d_name, d_street_1, d_street_2, d_city, d_state, d_zip 
    INTO d_name, d_street_1, d_street_2, d_city, d_state, d_zip;

    -- Get customer
    IF p_c_id IS NOT NULL THEN
        -- Customer selected by ID
        SELECT c_id, c_first, c_middle, c_last, c_street_1, c_street_2, c_city, c_state, c_zip, c_phone, c_since, c_credit, c_credit_lim, c_discount, c_balance, c_data 
        INTO c_id, c_first, c_middle, c_last, c_street_1, c_street_2, c_city, c_state, c_zip, c_phone, c_since, c_credit, c_credit_lim, c_discount, c_balance, c_data 
        FROM bmsql_customer 
        WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND c_id = p_c_id;
        
        -- Update customer
        UPDATE bmsql_customer 
        SET c_balance = c_balance - p_h_amount, c_ytd_payment = c_ytd_payment + p_h_amount, c_payment_cnt = c_payment_cnt + 1 
        WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND c_id = p_c_id;
        
        IF c_credit = 'BC' THEN
            v_c_data_new := LEFT(CONCAT(c_id::text, p_c_d_id::text, p_c_w_id::text, p_d_id::text, p_w_id::text, p_h_amount::text, c_data), 500);
            UPDATE bmsql_customer 
            SET c_data = v_c_data_new 
            WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND c_id = p_c_id 
            RETURNING c_data INTO c_data;
        END IF;
    ELSE
        -- Customer selected by last name
        SELECT count(*) INTO v_c_row_count 
        FROM bmsql_customer 
        WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND c_last = p_c_last;
        
        SELECT c_id, c_first, c_middle, c_last, c_street_1, c_street_2, c_city, c_state, c_zip, c_phone, c_since, c_credit, c_credit_lim, c_discount, c_balance, c_data 
        INTO c_id, c_first, c_middle, c_last, c_street_1, c_street_2, c_city, c_state, c_zip, c_phone, c_since, c_credit, c_credit_lim, c_discount, c_balance, c_data 
        FROM (
            SELECT c_id, c_first, c_middle, c_last, c_street_1, c_street_2, c_city, c_state, c_zip, c_phone, c_since, c_credit, c_credit_lim, c_discount, c_balance, c_data, 
            ROW_NUMBER() OVER (ORDER BY c_first) as row_num 
            FROM bmsql_customer 
            WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND c_last = p_c_last
        ) AS subquery 
        WHERE row_num = CEIL(v_c_row_count / 2.0);
        
        -- Update customer
        UPDATE bmsql_customer 
        SET c_balance = c_balance - p_h_amount, c_ytd_payment = c_ytd_payment + p_h_amount, c_payment_cnt = c_payment_cnt + 1 
        WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND c_id = c_id;
        
        IF c_credit = 'BC' THEN
            v_c_data_new := LEFT(CONCAT(c_id::text, p_c_d_id::text, p_c_w_id::text, p_d_id::text, p_w_id::text, p_h_amount::text, c_data), 500);
            UPDATE bmsql_customer 
            SET c_data = v_c_data_new 
            WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND c_id = c_id 
            RETURNING c_data INTO c_data;
        END IF;
    END IF;

    -- Insert history
    v_h_data := CONCAT(w_name, '    ', d_name);
    h_date := CURRENT_TIMESTAMP;
    INSERT INTO bmsql_history (h_c_id, h_c_d_id, h_c_w_id, h_d_id, h_w_id, h_date, h_amount, h_data) 
    VALUES (c_id, p_c_d_id, p_c_w_id, p_d_id, p_w_id, h_date, p_h_amount, v_h_data);

    RETURN QUERY 
    SELECT 
        c_id, 
        w_name, 
        w_street_1, 
        w_street_2, 
        w_city, 
        w_state, 
        w_zip, 
        d_name, 
        d_street_1, 
        d_street_2, 
        d_city, 
        d_state, 
        d_zip, 
        c_first, 
        c_middle, 
        c_last, 
        c_street_1, 
        c_street_2, 
        c_city, 
        c_state, 
        c_zip, 
        c_phone, 
        c_since, 
        c_credit, 
        c_credit_lim, 
        c_discount, 
        c_balance, 
        CASE WHEN c_credit = 'BC' THEN LEFT(c_data, 200) ELSE '' END, 
        h_date;
END;
$$;