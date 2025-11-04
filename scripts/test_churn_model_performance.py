import mlflow
from sklearn.metrics import classification_report
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LogisticRegression
from sklearn.preprocessing import StandardScaler, OneHotEncoder
from sklearn.compose import ColumnTransformer
from sklearn.pipeline import Pipeline

# Carregar os dados
df = pd.read_parquet("s3://curated-zone/processed_telco_churn.parquet")

df['Churn'] = df['Churn'].apply(lambda x: 1 if x == 'Yes' else 0)
df = df.drop(columns=['customerID'])
X = df.drop('Churn', axis=1)
y = df['Churn']
numeric_features = X.select_dtypes(include=['int64', 'float64']).columns
categorical_features = X.select_dtypes(include=['object']).columns

preprocessor = ColumnTransformer(
    transformers=[
        ('num', StandardScaler(), numeric_features),
        ('cat', OneHotEncoder(handle_unknown='ignore'), categorical_features)])

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42, stratify=y)

# Carregar o modelo treinado
model = mlflow.sklearn.load_model("models:/churn_prediction_model/1")

# Fazer previsões
y_pred = model.predict(X_test)

# Avaliar o modelo
print(classification_report(y_test, y_pred))

