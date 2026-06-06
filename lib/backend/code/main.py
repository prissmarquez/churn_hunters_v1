import pandas as pd

# Cargar CSVs
clientes = pd.read_csv("lib/backend/data/Clientes.csv")
coolers = pd.read_csv("lib/backend/data/Coolers.csv")
ventas_train = pd.read_csv("lib/backend/data/sales_churn_train.csv")
ventas_test = pd.read_csv("lib/backend/data/sales_churn_test.csv")

#Ver primeras filas que tenemos 
print("Clientes:")
print(clientes.head(), "\n")

print("Coolers:")
print(coolers.head(), "\n")

print("Ventas train:")
print(ventas_train.head(), "\n")

print("Ventas test:")
print(ventas_test.head(), "\n")

#Revisar tipos de datos y nulos
print("Info Clientes:")
print(clientes.info(), "\n")

print("Info Coolers:")
print(coolers.info(), "\n")

print("Info Ventas train:")
print(ventas_train.info(), "\n")

# Estadísticas básicas
print("Estadísticas Ventas train:")
print(ventas_train.describe(), "\n")

print("Estadísticas Coolers:")
print(coolers.describe(), "\n")