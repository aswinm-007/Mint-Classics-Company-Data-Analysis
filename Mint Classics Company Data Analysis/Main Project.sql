-- Warehouse & Inventory Optimization

-- Q1. Where are items stored and how many per warehouse?

SELECT
	w.warehouseCode,
	w.warehouseName,
   	COUNT(p.productCode) AS productCount
FROM
	warehouses w
JOIN 
	products p ON w.warehouseCode = p.warehouseCode
GROUP BY
	w.warehouseCode,
	w.warehouseName
ORDER BY
	productCount DESC;

-- Insight: East warehouse holds the most unique products, while the South warehouse holds the fewest.
-- Implication: The South warehouse is potentially redundant and a prime candidate for closure.

-- Q2. What is the total quantity of products in stock per warehouse?

SELECT
	w.warehouseCode,
	w.warehouseName,
	SUM(p.quantityInStock) AS totalStock
FROM
	warehouses w
JOIN 
	products p ON w.warehouseCode = p.warehouseCode
GROUP BY
	w.warehouseCode,
	w.warehouseName;

-- Insight: Warehouses vary significantly in total stock levels.
-- Implication: Warehouses with minimal stock contribute less operationally.

-- Q3. Are there any warehouses with significantly lower inventory than others?

SELECT 
	w.warehouseCode,
	w.warehouseName,
	SUM(p.quantityInStock) AS totalInventory
FROM 
	warehouses w 
JOIN 
	products p ON w.warehouseCode = p.warehouseCode
GROUP BY 
	warehouseCode,
	warehouseName
ORDER BY 
	totalInventory ASC;

-- Insight: The South warehouse has the least stock overall.
-- Implication: Consider redistributing inventory and closing this location.

-- Q4. Could inventory from one warehouse be redistributed to others?

SELECT
	w.warehouseCode,
	w.warehouseName,
	COUNT(p.productCode) AS productTypes,
	SUM(p.quantityInStock) AS totalStock
FROM
	warehouses w
JOIN 
	products p ON w.warehouseCode = p.warehouseCode
GROUP BY
	w.warehouseCode,
	w.warehouseName;

-- Insight: The South warehouse has both low quantity and variety, making redistribution feasible.
-- Implication: Supports a shutdown plan with minimal disruption.

-- Q5. What percentage of total inventory does each warehouse hold?

SELECT
	w.warehouseCode,
	w.warehouseName,
	COUNT(p.productCode) AS productCount,
	SUM(p.quantityInStock) AS totalInventory,
	ROUND(SUM(p.quantityInStock) * 100 / (SELECT SUM(p.quantityInStock) FROM products p), 2) AS percentOfInventory
FROM
	warehouses w
JOIN 
	products p ON w.warehouseCode = p.warehouseCode
GROUP BY
	w.warehouseCode,
	w.warehouseName;

-- Insight: South warehouse holds <20% of inventory.
-- Implication: Further justifies its closure with minimal impact on supply chain efficiency.

-- Sales vs. Inventory

-- Q6. Which products have the highest and lowest sales volumes?

SELECT 
	p.productCode, 
	p.productName, 
	SUM(od.quantityOrdered) AS totalSold
FROM 
	products p
JOIN 
	orderdetails od ON p.productCode = od.productCode
GROUP BY 
	p.productCode, p.productName
ORDER BY 
	totalSold DESC;

-- Insight: 
-- •	Best seller: 1992 Ferrari 360 Spider red. 
-- •	Lowest: 1957 Ford Thunderbird.
-- Implication: Focus restocking on high-demand products, consider discontinuing low performers.

-- Q7. Is there any inventory that hasn’t been ordered in a long time?

SELECT 
	p.productCode, 
	p.productName, 
	MAX(o.orderDate) AS lastOrderDate
FROM 
	products p
JOIN 
	orderdetails od ON p.productCode = od.productCode
JOIN 
	orders o ON od.orderNumber = o.orderNumber
GROUP BY 
	p.productCode, p.productName
ORDER BY 
	lastOrderDate ASC;
    
-- Insight: Products with very old last order dates suggest declining demand.
-- Implication: Review for clearance or removal.

-- Q8. Are there products with high stock but low sales?

SELECT 
	p.productCode, p.productName, p.quantityInStock, 
	SUM(od.quantityOrdered) AS totalSold
FROM 
	products p
LEFT JOIN 
	orderdetails od ON p.productCode = od.productCode
GROUP BY 
	p.productCode, p.productName, p.quantityInStock
HAVING 
	totalSold < 1000 AND p.quantityInStock > 5000;

-- Insight: 44 such products exist — overstocked and underperforming.
-- Implication: Candidates for markdowns, clearance, or SKU rationalization.

-- Q9. What is the average quantity ordered per product vs. quantity in stock?

SELECT 
	p.productCode, p.productName, 
	AVG(od.quantityOrdered) AS avgOrdered,
	p.quantityInStock
FROM 
	products p
JOIN 
	orderdetails od ON p.productCode = od.productCode
GROUP BY 
	p.productCode, 
	p.productName, 
	p.quantityInStock;

-- Insight: Large discrepancies show demand misalignment.
-- Implication: Adjust stock levels based on historical order patterns.

-- Q10. Do inventory levels align with product demand?

SELECT 
	p.productCode, 
	p.productName, 
	p.quantityInStock,
	SUM(od.quantityOrdered) AS totalSold
FROM 
	products p
LEFT JOIN 
	orderdetails od ON p.productCode = od.productCode
GROUP BY 
	p.productCode, 
	p.productName, 
	p.quantityInStock
ORDER BY 
	totalSold DESC;

-- Insight: Visualizes stock-to-demand efficiency.
-- Implication: Avoid overstocking slow sellers, prioritize replenishing fast movers.

-- Product Line & Operational Efficiency

-- Q11. Which product lines generate the most revenue?

SELECT 
	p.productLine, 
	ROUND(SUM(od.quantityOrdered * od.priceEach), 2) AS totalRevenue
FROM 
	products p
JOIN 
	orderdetails od ON p.productCode = od.productCode
GROUP BY 
	p.productLine
ORDER BY 
	totalRevenue DESC;

-- Insight: Classic Cars dominate revenue.
-- Implication: Prioritize inventory space and marketing efforts accordingly.

-- Q12. Are there underperforming product lines?

SELECT 
	p.productLine, 
	ROUND(SUM(od.quantityOrdered * od.priceEach), 2) AS totalRevenue
FROM 
	products p
JOIN 
	orderdetails od ON p.productCode = od.productCode
GROUP BY 
	p.productLine
ORDER BY 
	totalRevenue ASC;

-- Insight: Trains line generates the least revenue.
-- Implication: Consider phasing out or reducing stock of this category.

-- Q13. What are the profit margins by product?

SELECT 
	productCode, 
	productName, 
	MSRP, 
	buyPrice,
	ROUND((MSRP - buyPrice) / buyPrice * 100, 2) AS profitMarginPercent
FROM 
	products
ORDER BY 
	profitMarginPercent ASC;

-- Insight: Some products yield very low margins.
-- Implication: Avoid investing storage space or promotions on low-profit SKUs.

-- Q14. How many orders are shipped within 24 hours?

SELECT 
    DATEDIFF(o.shippedDate, o.orderDate) AS shippingDays,
    COUNT(*) AS orderCount
FROM 
    orders o
WHERE 
    o.shippedDate IS NOT NULL AND o.orderDate IS NOT NULL
GROUP BY 
    shippingDays
ORDER BY 
    shippingDays;
    
-- Insight: 50 orders were shipped promptly.
-- Implication: Indicates capacity to meet fast delivery; must be preserved in future reorganization.

-- Operational Bottlenecks & Warehouse Performance

-- Q15. Are there any delays in shipping due to stock shortages?

SELECT 
	status, 
	COUNT(*) AS orderCount
FROM 
	orders
WHERE 
	status IN ('On Hold', 'In Process')
GROUP BY 
	status;

-- Insight: 4 on hold, 6 in process.
-- Implication: Some delays possibly linked to inventory availability or operational inefficiencies.

-- Q16. Which warehouses fulfill the most customer orders?

SELECT 
	p.warehouseCode,
	w.warehouseName,
	COUNT(DISTINCT od.orderNumber) AS totalOrdersFulfilled
FROM 
	products p
JOIN 
	orderdetails od ON p.productCode = od.productCode
JOIN 
	warehouses w ON p.warehouseCode = w.warehouseCode
GROUP BY 
	p.warehouseCode,
	w.warehouseName
ORDER BY 
	totalOrdersFulfilled DESC;

-- Insight: North warehouse fulfills the fewest orders.
-- Implication: Lower priority for operations; candidate for resource reallocation or closure.

-- Q17. Which products can be considered for clearance or discontinuation?

SELECT 
	p.productCode, 
	p.productName, 
	p.quantityInStock, 
	SUM(od.quantityOrdered) AS totalSold
FROM 
	products p
LEFT JOIN 
	orderdetails od ON p.productCode = od.productCode
GROUP BY 
	p.productCode, p.productName, p.quantityInStock
HAVING 
	totalSold = 0 OR (totalSold < 1000 AND p.quantityInStock > 5000);
    
-- Insight: High stock + low sales items spotted.
-- Implication: Optimize inventory and free up space by phasing these out.

-- Q18. Which warehouse is the best candidate for closure?

SELECT 
	p.warehouseCode,
	w.warehouseName,
	COUNT(DISTINCT p.productCode) AS productTypes,
	SUM(p.quantityInStock) AS totalInventory,
	COUNT(DISTINCT od.orderNumber) AS totalOrdersFulfilled
FROM 
	products p
LEFT JOIN 
	orderdetails od ON p.productCode = od.productCode
LEFT JOIN
	warehouses w ON p.warehouseCode = w.warehouseCode
GROUP BY 
	p.warehouseCode
ORDER BY 
	totalInventory ASC, totalOrdersFulfilled ASC;

-- Insight: South warehouse has low stock and variety, North warehouse has low fulfillment.
-- Implication: Both are candidates — South warehouse based on inventory, North warehouse based on operations.

-- Q19. How much space could be saved by removing slow-moving items?

SELECT 
	SUM(quantityInStock) AS totalSpaceSaved
FROM 
	products
WHERE 
	productCode IN (
	SELECT 
		p.productCode
	FROM 
		products p
	LEFT JOIN 
		orderdetails od ON p.productCode = od.productCode
	GROUP BY 
		p.productCode
	HAVING 
		SUM(od.quantityOrdered) < 900
);

-- Insight: 69598 stock units could be cleared.
-- Implication: Huge opportunity for space optimization and operational cost reduction.