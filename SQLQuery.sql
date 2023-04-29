-- 找出和最貴的產品同類別的所有產品

SELECT c.CategoryName, p.ProductID, p.ProductName
FROM Products p
INNER JOIN Categories c ON c.CategoryID = (
SELECT p.CategoryID
FROM Products p
WHERE p.UnitPrice =
(
SELECT MAX(UnitPrice)
FROM Products p
));

-- 找出和最貴的產品同類別最便宜的產品

select top 1 *
from Products
where CategoryID=(
select top 1 CategoryID
from Products
order by UnitPrice desc
)
order by UnitPrice

-- 計算出上面類別最貴和最便宜的兩個產品的價差

select max(UnitPrice)-min(UnitPrice)
from Products
where CategoryID=(
select top 1 CategoryID
from Products
order by UnitPrice desc
)

-- 找出沒有訂過任何商品的客戶所在的城市的所有客戶

select *
from Customers
where City in (
select c.City
from Customers c
left join Orders o on o.CustomerID=c.CustomerID
where o.OrderID is null)


-- 找出第 5 貴跟第 8 便宜的產品的產品類別

select *
from(select *,ROW_NUMBER() over (order by UnitPrice desc) as number from Products)t
inner join Categories c on c.CategoryID=t.CategoryID
where number=5 or number=(select COUNT(*) from Products)-7


-- 找出誰買過第 5 貴跟第 8 便宜的產品

select distinct o.CustomerID
from Orders o
join [Order Details] od on od.OrderID=o.OrderID
join Products p on p.ProductID=od.ProductID
join Categories c on c.CategoryID=p.CategoryID
join Customers ct on ct.CustomerID=o.CustomerID
where p.ProductName in(
select ProductName
from (select *,ROW_NUMBER() over (order by UnitPrice desc) as number from Products)t
inner join Categories c on c.CategoryID=t.CategoryID
where t.number=5 or t.number=(select COUNT(*) from Products)-7
)


-- 找出誰賣過第 5 貴跟第 8 便宜的產品

select distinct SupplierID,CompanyName
from Orders o
join [Order Details] od on od.OrderID=o.OrderID
join Products p on p.ProductID=od.ProductID
join Categories c on c.CategoryID=p.CategoryID
join Customers ct on ct.CustomerID=o.CustomerID
where p.ProductName in(
select ProductName
from (select *,ROW_NUMBER() over (order by UnitPrice desc) as number from Products)t
inner join Categories c on c.CategoryID=t.CategoryID
where t.number=5 or t.number=(select COUNT(*) from Products)-7
)

-- 找出 13 號星期五的訂單 (惡魔的訂單)

select *
from Orders
where DATEPART(WEEKDAY,OrderDate)=6 and DATEPART(DAY,OrderDate)=13

-- 找出誰訂了惡魔的訂單

select o.CustomerID,c.ContactName
from Orders o
inner join Customers c on c.CustomerID=o.CustomerID
where DATEPART(WEEKDAY,OrderDate)=6 and DATEPART(DAY,OrderDate)=13


-- 找出惡魔的訂單裡有什麼產品

select o.OrderDate,p.ProductID,p.ProductName
from Orders o
inner join [Order Details] od on od.OrderID=o.OrderID
inner join Products p on p.ProductID=od.ProductID
where DATEPART(WEEKDAY,OrderDate)=6 and DATEPART(DAY,OrderDate)=13

-- 列出從來沒有打折 (Discount) 出售的產品

select *
from [Order Details] o
inner join Products p on p.ProductID=o.ProductID
where o.Discount=0

-- 列出購買非本國的產品的客戶

select distinct c.CustomerID
from Orders o
inner join Customers c on c.CustomerID=o.CustomerID
inner join [Order Details] od on od.OrderID=o.OrderID
inner join Products p on p.ProductID=od.ProductID
inner join Suppliers s on s.SupplierID=p.SupplierID
where s.Country!=c.Country

-- 列出在同個城市中有公司員工可以服務的客戶

select distinct c.CustomerID,c.ContactName
from Orders o
inner join Customers c on c.CustomerID=o.CustomerID
inner join Employees e on e.EmployeeID=o.EmployeeID
where e.City=c.City

-- 列出那些產品沒有人買過

select *
from Products p
left join [Order Details] od on od.ProductID=p.ProductID
where p.ProductID is null

----------------------------------------------------------------------------------------

-- 列出所有在每個月月底的訂單

select *
from Orders
where OrderDate=EOMONTH(OrderDate)

-- 列出每個月月底售出的產品

select p.*,o.OrderDate
from Products p
inner join [Order Details] od on od.ProductID=p.ProductID
inner join Orders o on o.OrderID=od.OrderID
where o.OrderDate in(
select OrderDate
from Orders
where OrderDate=EOMONTH(OrderDate)
)

-- 找出有敗過最貴的三個產品中的任何一個的前三個大客戶
select top 3 c.CustomerID,(
select sum(od.UnitPrice*od.Quantity*(1-od.Discount))
) as total
from Orders o
inner join [Order Details] od on od.OrderID=o.OrderID
inner join Customers c on c.CustomerID=o.CustomerID
where od.ProductID in(
select top 3 ProductID
from Products
order by UnitPrice desc
)
group by c.CustomerID
order by total desc


-- 找出有敗過銷售金額前三高個產品的前三個大客戶

select top 3 c.CustomerID,sum(od.UnitPrice*od.Quantity*(1-od.Discount)) as total
from Customers c
inner join Orders o on o.CustomerID=c.CustomerID
inner join [Order Details] od on od.OrderID=o.OrderID
inner join Products p on p.ProductID=od.ProductID
where p.ProductID in (
select top 3 p.ProductID
from [Order Details] od
inner join Products p on p.ProductID=od.ProductID
inner join Orders o on o.OrderID=od.OrderID
group by p.ProductID
order by sum(od.UnitPrice*od.Quantity*(1-od.Discount))desc)
group by c.CustomerID
order by total desc

-- 找出有敗過銷售金額前三高個產品所屬類別的前三個大客戶 

with t1 as(select top 3 p.ProductID,p.CategoryID
from [Order Details] od 
left join Products p on p.ProductID=od.ProductID
group by p.ProductID,p.CategoryID
order by sum(od.UnitPrice*od.Quantity*(1-od.Discount)) desc)
select top 3 o.CustomerID
from Products p
left join [Order Details] od on od.ProductID=p.ProductID
left join Orders o on o.OrderID=od.OrderID
where p.CategoryID in (
select CategoryID
from t1
)
group by o.CustomerID
order by sum(od.UnitPrice*od.Quantity*(1-od.Discount))desc


-- 列出消費總金額高於所有客戶平均消費總金額的客戶的名字，以及客戶的消費總金額

select c.CustomerID,sum(od.UnitPrice*od.Quantity*(1-od.Discount)) as total
from Customers c
inner join Orders o on o.CustomerID=c.CustomerID
inner join [Order Details] od on od.OrderID=o.OrderID
group by c.CustomerID
HAVING sum(od.UnitPrice*od.Quantity*(1-od.Discount))>(select AVG(od.UnitPrice*od.Quantity*(1-od.Discount)) from [Order Details] od inner join Orders o on o.OrderID=od.OrderID)

-- 列出最熱銷的產品，以及被購買的總金額

select ProductID,sum(UnitPrice*Quantity*(1-Discount))as total
from [Order Details]
where ProductID=(
select top 1 p.ProductID
from Products p
inner join [Order Details] od on od.ProductID=p.ProductID
group by p.ProductID
order by sum(od.Quantity) desc
)
group by ProductID

-- 列出最少人買的產品

select top 1 p.ProductID,p.ProductName,sum(od.Quantity) as sell
from [Order Details] od
inner join Products p on p.ProductID=od.ProductID
group by p.ProductID,p.ProductName
order by sell

-- 列出最沒人要買的產品類別 (Categories)

select top 1 c.CategoryID,sum(od.Quantity)as sell
from Categories c
inner join Products p on p.CategoryID=c.CategoryID
inner join [Order Details] od on od.ProductID=p.ProductID
group by c.CategoryID
order by sell

-- 列出跟銷售最好的供應商買最多金額的客戶與購買金額 (含購買其它供應商的產品)

SELECT TOP 1 SUM((od.UnitPrice*od.Quantity)*(1-od.Discount)) totalPriec, c.CustomerID
FROM Customers c
INNER JOIN Orders o ON o.CustomerID = c.CustomerID
INNER JOIN [Order Details] od ON od.OrderID = o.OrderID
INNER JOIN Products p ON p.ProductID = od.ProductID
WHERE p.SupplierID = (
SELECT TOP 1 s.SupplierID
FROM Suppliers s
INNER JOIN Products p ON p.SupplierID = s.SupplierID
INNER JOIN [Order Details] od ON od.ProductID = p.ProductID
GROUP BY s.SupplierID
ORDER BY SUM(od.Quantity) DESC)
GROUP BY c.CustomerID
ORDER BY totalPriec DESC

-- 列出跟銷售最好的供應商買最多金額的客戶與購買金額 (不含購買其它供應商的產品)

SELECT TOP 1 SUM((od.UnitPrice*od.Quantity)*(1-od.Discount)) totalPriec, c.CustomerID
FROM Customers c
INNER JOIN Orders o ON o.CustomerID = c.CustomerID
INNER JOIN [Order Details] od ON od.OrderID = o.OrderID
INNER JOIN Products p ON p.ProductID = od.ProductID
WHERE p.SupplierID = (
SELECT TOP 1 s.SupplierID
FROM Suppliers s
INNER JOIN Products p ON p.SupplierID = s.SupplierID
INNER JOIN [Order Details] od ON od.ProductID = p.ProductID
GROUP BY s.SupplierID
ORDER BY SUM(od.Quantity) DESC)
GROUP BY c.CustomerID
ORDER BY totalPriec DESC

-- 列出那些產品沒有人買過

select *
from Products p
left join [Order Details] od on od.ProductID=p.ProductID
where od.Quantity is null

-- 列出沒有傳真 (Fax) 的客戶和它的消費總金額

select c.CustomerID,sum(od.UnitPrice*od.Quantity*(1-od.Discount)) as total
from Customers c
inner join Orders o on o.CustomerID=c.CustomerID
inner join [Order Details] od on o.OrderID=od.OrderID
where c.Fax is null
group by c.CustomerID

-- 列出每一個城市消費的產品種類數量

select t.City,count(t.CategoryID)as num
from(
select distinct c.City,p.CategoryID
from Customers c
inner join Orders o on o.CustomerID=c.CustomerID
inner join [Order Details] od on od.OrderID=o.OrderID
inner join Products p on p.ProductID=od.ProductID
) t
group by t.City

-- 列出目前沒有庫存的產品在過去總共被訂購的數量

SELECT
p.ProductName,SUM(od.Quantity) AS Total
FROM Products p
INNER join [Order Details] od on od.ProductID=p.ProductID
WHERE  p.UnitsInStock='0'
GROUP BY p.ProductName

-- 列出目前沒有庫存的產品在過去曾經被那些客戶訂購過

select distinct o.CustomerID
from Products p
inner join [Order Details] od on od.ProductID=p.ProductID
inner join Orders o on o.OrderID=od.OrderID
where p.UnitsInStock='0'

-- 列出每位員工的下屬的業績總金額

SELECT e.ReportsTo ,SUM(od.Quantityod.UnitPrice(1-od.Discount)) TotalAchievement
FROM Employees e
INNER JOIN Orders o ON o.EmployeeID = e.EmployeeID
INNER JOIN [Order Details] od ON od.OrderID = o.OrderID
WHERE e.ReportsTo IS NOT NULL
GROUP BY e.ReportsTo;



-- 列出每家貨運公司運送最多的那一種產品類別與總數量

WITH t1 AS (
    SELECT s.ShipperID, c.CategoryName, SUM(od.Quantity) AS TotalQuantity,
        ROW_NUMBER() OVER (PARTITION BY s.ShipperID ORDER BY SUM(od.Quantity) DESC) AS RowNumber
    FROM [Order Details] od
    INNER JOIN Products p ON p.ProductID = od.ProductID
    INNER JOIN Categories c ON c.CategoryID = p.CategoryID
    INNER JOIN Orders o ON o.OrderID = od.OrderID
    INNER JOIN Shippers s ON s.ShipperID = o.ShipVia
    GROUP BY s.ShipperID, c.CategoryName
)
SELECT ShipperID, CategoryName, TotalQuantity
FROM t1
WHERE RowNumber = 1


-- 列出每一個客戶買最多的產品類別與金額

with t1 as(
select c.CustomerID,p.CategoryID,sum(od.Quantity) as Qty,sum(od.UnitPrice*od.Quantity*(1-od.Discount))as price
from Customers c
inner join Orders o on o.CustomerID=c.CustomerID
inner join [Order Details] od on od.OrderID=o.OrderID
inner join Products p on p.ProductID=od.ProductID
group by c.CustomerID,p.CategoryID
),
t2 as(
select *,rank() over(partition by CustomerID order by Qty desc)as rk
from t1)
select CustomerID,CategoryID,price
from t2
where rk=1

-- 列出每一個客戶買最多的那一個產品與購買數量

with t1 as(select o.CustomerID,od.ProductID,sum(od.Quantity)as q
from Orders o
inner join [Order Details] od on od.OrderID=o.OrderID
group by o.CustomerID,od.ProductID),
t2 as(
select *,rank() over (partition by CustomerID order by q desc) as qu
from t1)
select CustomerID,ProductID,q
from t2
where qu=1

-- 按照城市分類，找出每一個城市最近一筆訂單的送貨時間

SELECT ShipCity, MAX(ShippedDate) recentDate
FROM ORDERS 
WHERE ShipCity IS NOT NULL
GROUP BY ShipCity;

-- 列出購買金額第五名與第十名的客戶，以及兩個客戶的金額差距

WITH t1 AS(
SELECT c.CustomerID, SUM((od.UnitPrice*od.Quantity)*(1-od.Discount)) SumPrice,
	ROW_NUMBER() OVER (
		ORDER BY SUM((od.UnitPrice*od.Quantity)*(1-od.Discount)) DESC
	) AS NoDesc
FROM Customers c
INNER JOIN Orders o ON o.CustomerID = c.CustomerID
INNER JOIN [Order Details] od ON od.OrderID = o.OrderID
GROUP BY c.CustomerID
)
SELECT t1.CustomerID, t1.SumPrice SumPrice1,  t2.CustomerID, t2.SumPrice SumPrice2, ABS(t1.SumPrice - t2.SumPrice) gap
FROM t1 t1
INNER JOIN t1 t2 ON t1.NoDesc = 5 AND t2.NoDesc = 10
WHERE t1.NoDesc = 5 OR t2.NoDesc = 10;