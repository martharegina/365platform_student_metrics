-- Creating indexes to improve query performance
-- Index for student_engagement
CREATE INDEX idx_engagement_student ON student_engagement(student_id);
CREATE INDEX idx_engagement_date ON student_engagement(date_watched);

-- Index for student_info
CREATE INDEX idx_info_student ON student_info(student_id);
CREATE INDEX idx_info_date ON student_info(date_registered);

-- Index for student_purchases
CREATE INDEX idx_purchases_student ON student_purchases(student_id);
CREATE INDEX idx_purchases_date ON student_purchases(date_purchased);

-- Creating a view to consolidate student registration, engagement, and purchase data
CREATE VIEW student_conversion AS
SELECT e.student_id,
	i.date_registered,
    MIN(e.date_watched) AS first_date_watched,
    MIN(p.date_purchased) AS first_date_purchased,
    (SELECT COUNT(p2.date_purchased) 
        FROM student_purchases p2 
        WHERE p2.student_id = e.student_id) AS total_purchases,
    DATEDIFF(MIN(e.date_watched), i.date_registered) AS date_diff_reg_watch,
    DATEDIFF(MIN(p.date_purchased), MIN(e.date_watched)) AS date_diff_watch_purch 
FROM student_engagement e
	LEFT JOIN student_info i ON e.student_id = i.student_id
    LEFT JOIN student_purchases p ON e.student_id = p.student_id
GROUP BY e.student_id, i.date_registered
HAVING MIN(e.date_watched) <= MIN(p.date_purchased) OR MIN(p.date_purchased) IS NULL;

-- Calculating key student metrics from the student_conversion view
SELECT 
	CONCAT(ROUND(COUNT(first_date_purchased) / COUNT(first_date_watched)  * 100, 2), '%') AS conversion_rate,
    ROUND(SUM(DATEDIFF(first_date_watched, date_registered)) / COUNT(first_date_watched), 2) AS avg_reg_watch,
    ROUND(SUM(DATEDIFF(first_date_purchased, date_registered)) / COUNT(first_date_purchased), 2) AS avg_reg_purch,
    ROUND(SUM(DATEDIFF(first_date_purchased, first_date_watched)) / COUNT(first_date_purchased), 2) AS avg_watch_purch,
    CONCAT(ROUND(COUNT(CASE WHEN total_purchases > 1 THEN 1 END) / COUNT(student_id) * 100, 2), '%') AS retention_rate,
    CONCAT(ROUND((COUNT(first_date_watched) - COUNT(first_date_purchased)) / COUNT(first_date_watched) * 100, 2), '%') AS churn_rate,
    CONCAT(ROUND(COUNT(CASE WHEN first_date_watched = first_date_purchased THEN 1 END) / COUNT(first_date_watched) * 100, 2), '%') AS same_day_conversion
FROM student_conversion;