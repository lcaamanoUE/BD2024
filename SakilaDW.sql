Drop database IF EXISTS SakilaDW;
CREATE DATABASE IF NOT EXISTS SakilaDW;
USE SakilaDW;
-- Dimension Fecha
CREATE TABLE DimFecha(
	FechaKey INT PRIMARY KEY AUTO_INCREMENT,
    Fecha DATE NOT NULL,
    Año INT NOT NULL,
    Trimestre INT NOT NULL,
    Mes INT NOT NULL,
    Dia INT NOT NULL,
    NombreMes VARCHAR(20),
    NombreDia VARCHAR(20),
    EsFinDeSemana BOOLEAN
);
-- Dimension Cliente
CREATE TABLE DimCliente(
ClienteKey INT PRIMARY KEY AUTO_INCREMENT,
IDCliente INT NOT NULL,
FullName VARCHAR(100),
Activo BOOLEAN NOT NULL DEFAULT TRUE,
City VARCHAR(50),
Country VARCHAR(50)
);
-- Dimension Empleado
CREATE TABLE DimEmpleado(
EmpleadoKey INT PRIMARY KEY AUTO_INCREMENT,
IDEmpleado INT NOT NULL,
FullName VARCHAR(100),
City VARCHAR(50),
Country VARCHAR(50)
);
-- Dimension Pelicula
CREATE TABLE DimPelicula(
PeliculaKey INT PRIMARY KEY AUTO_INCREMENT,
IDPelicula INT NOT NULL,
Title VARCHAR(218),
Release_year YEAR,
languaje CHAR(20),
Rental_Rate DECIMAL(4,2),
Rating ENUM('G','PG','PG-13','R','NC-17') DEFAULT 'G'
);

-- Tabla Actor
CREATE TABLE DimActor (
    ActorKey INT PRIMARY KEY AUTO_INCREMENT,
    ActorID INT NOT NULL,
    FullName VARCHAR(100)
);

-- Tabla Categoria
CREATE TABLE DimCategory (
    CategoryKey INT PRIMARY KEY AUTO_INCREMENT,
    CategoryID INT NOT NULL,
    CategoryName VARCHAR(50)
);

-- Tabla central
CREATE TABLE Rental (
RentalKey INT PRIMARY KEY AUTO_INCREMENT,
ClienteKey INT NOT NULL,
EmpleadoKey INT NOT NULL,
PeliculaKey INT NOT NULL,
FechaKey INT NOT NULL,
Amount_Total DECIMAL(10, 2) NOT NULL,
FOREIGN KEY (ClienteKey) REFERENCES DimCliente(ClienteKey),
FOREIGN KEY (EmpleadoKey) REFERENCES DimEmpleado(EmpleadoKey),
FOREIGN KEY (FechaKey) REFERENCES DimFecha(FechaKey),
FOREIGN KEY (PeliculaKey) REFERENCES DimPelicula(PeliculaKey)
);

-- ______________INSERTAR DATOS__________________

-- DIMENSION FECHA
INSERT IGNORE INTO DimFecha (FechaKey, Fecha, Año, Trimestre, Mes, Dia, NombreMes, NombreDia, EsFinDeSemana)
SELECT 
    DATE_FORMAT(rental_date, '%Y%m%d') AS FechaKey,
    rental_date AS Fecha,
    YEAR(rental_date) AS Año,
    QUARTER(rental_date) AS Trimestre,
    MONTH(rental_date) AS Mes,
    DAY(rental_date) AS Dia,
    MONTHNAME(rental_date) AS NombreMes,
    DAYNAME(rental_date) AS NombreDia,
    IF(DAYOFWEEK(rental_date) IN (1, 7), TRUE, FALSE) AS EsFinDeSemana
FROM 
    Sakila.rental
GROUP BY 
    rental_date;

    
-- DIMENSION CLIENTE
INSERT INTO DimCliente (IDCliente, FullName, Activo, City, Country)
SELECT 
    cli.customer_id AS IDCliente,
    CONCAT(cli.first_name, ' ', cli.last_name) AS FullName,
    cli.active AS Activo,
    cit.city AS City,
    con.country AS Country
FROM 
    sakila.customer cli
JOIN
    sakila.address adr ON cli.address_id = adr.address_id
JOIN
    sakila.city cit ON adr.city_id = cit.city_id
JOIN
    sakila.country con ON cit.country_id = con.country_id;


-- DIMENSION EMPLEADO
INSERT INTO DimEmpleado (IDEmpleado, FullName, City, Country)
SELECT 
    st.staff_id AS IDEmpleado,
    CONCAT(st.first_name, ' ', st.last_name) AS FullName,
    cit.city AS City,
    con.country AS Country
FROM 
    sakila.staff st
JOIN
    sakila.address adr ON st.address_id = adr.address_id
JOIN
    sakila.city cit ON adr.city_id = cit.city_id
JOIN
    sakila.country con ON cit.country_id = con.country_id;



-- DIMENSION PELICULA
INSERT INTO DimPelicula (IDPelicula, Title, Release_year, languaje, Rental_Rate, Rating)
SELECT 
    f.film_id AS IDPelicula,
    f.title AS Title, 
    f.release_year AS Release_year,
    l.name AS languaje,
    f.rental_rate AS Rental_Rate,
    f.rating AS Rating
FROM 
    sakila.film f
JOIN
    sakila.language l ON f.language_id = l.language_id;

    
-- DIMENSION ACTOR
INSERT IGNORE INTO DimActor (ActorID, FullName)
SELECT DISTINCT
    ac.actor_id AS ActorID,
    CONCAT(ac.first_name, ' ', ac.last_name) AS FullName
FROM
    sakila.actor ac;


-- DIMENSION CATEGORIA
INSERT IGNORE INTO DimCategory (CategoryID, CategoryName)
SELECT DISTINCT
    c.category_id AS CategoryID,
    c.name AS CategoryName
FROM
    sakila.category c;

 
 -- ALQUILER
INSERT INTO Rental (ClienteKey, EmpleadoKey, PeliculaKey, FechaKey, Amount_Total)
SELECT
    cli.customer_id AS ClienteKey,
    em.staff_id AS EmpleadoKey,
    pe.film_id AS PeliculaKey,
    DATE_FORMAT(ren.rental_date, '%Y%m%d') AS FechaKey,
    SUM(pay.amount) AS Amount_Total
FROM
    sakila.rental ren
JOIN
    sakila.customer cli ON ren.customer_id = cli.customer_id
JOIN
    sakila.staff em ON ren.staff_id = em.staff_id
JOIN
    sakila.inventory inv ON ren.inventory_id = inv.inventory_id
JOIN
    sakila.film pe ON inv.film_id = pe.film_id
JOIN
    sakila.payment pay ON ren.rental_id = pay.rental_id
GROUP BY
    cli.customer_id, em.staff_id, pe.film_id, DATE_FORMAT(ren.rental_date, '%Y%m%d');
    
