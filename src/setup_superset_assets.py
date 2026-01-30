import logging
import json
from superset.app import create_app

# 1. Start App context strictly before importing models that rely on encryption
app = create_app()
app.app_context().push()

from superset import db
from superset.models.core import Database
from superset.connectors.sqla.models import SqlaTable
from superset.models.slice import Slice
from superset.models.dashboard import Dashboard
from superset.extensions import security_manager

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("ISP_Assets")

def setup_assets():
    with app.app_context():
        logger.info("Iniciando criação de ativos do Data Lake...")
        
        # 1. Obter ou Criar Conexão com Banco de Dados
        db_name = "DataLake Trino"
        database = db.session.query(Database).filter_by(database_name=db_name).first()
        
        if not database:
            logger.info(f"Criando conexão com banco de dados: {db_name}")
            database = Database(
                database_name=db_name,
                sqlalchemy_uri="trino://admin@datalake-trino:8080/iceberg/default"
            )
            db.session.add(database)
            db.session.commit()
        else:
            logger.info(f"Conexão '{db_name}' já existe.")
            
        # ---------------------------------------------------------
        # Funcoes auxiliares
        # ---------------------------------------------------------
        def get_or_create_dataset(name, sql=None, schema="default"):
            ds = db.session.query(SqlaTable).filter_by(
                table_name=name, 
                database_id=database.id
            ).first()
            if not ds:
                logger.info(f"Criando dataset: {name}")
                ds = SqlaTable(
                    table_name=name,
                    schema=schema,
                    database=database,
                    sql=sql  # Se tiver SQL, eh um Dataset Virtual
                )
                try:
                    ds.fetch_metadata()
                    db.session.add(ds)
                    db.session.commit()
                except Exception:
                    # Fallback suave se o SQL for invalido ou tabela nao existir
                    db.session.add(ds)
                    db.session.commit()
            return ds

        def get_or_create_dashboard(title, slug):
            dash = db.session.query(Dashboard).filter_by(dashboard_title=title).first()
            if not dash:
                logger.info(f"Criando dashboard: {title}")
                dash = Dashboard(
                    dashboard_title=title,
                    slug=slug,
                    published=True
                )
                db.session.add(dash)
                db.session.commit()
            return dash
            
        def grant_access_to_dataset(role_name, dataset):
            role = security_manager.find_role(role_name)
            if role and dataset:
                perm_view = security_manager.find_permission_view_menu(
                    "datasource_access", 
                    dataset.perm
                )
                if not perm_view:
                     # Se nao existir, cria
                     security_manager.add_permission_view_menu("datasource_access", dataset.perm)
                     perm_view = security_manager.find_permission_view_menu("datasource_access", dataset.perm)

                if perm_view and perm_view not in role.permissions:
                    role.permissions.append(perm_view)
                    db.session.commit()
                    logger.info(f"Permissão '{dataset.table_name}' adicionada a {role_name}")

        # ---------------------------------------------------------
        # 1. Configurar NOC (Ja existente, mas garantindo)
        # ---------------------------------------------------------
        ds_noc = get_or_create_dataset("customer_events_raw")
        dash_noc = get_or_create_dashboard("NOC - Monitoramento de Eventos", "noc_monitoring")
        grant_access_to_dataset("ISP_NOC", ds_noc)

        # ---------------------------------------------------------
        # 2. Configurar Comercial (Sales)
        # ---------------------------------------------------------
        # Simula uma View de Vendas
        sql_sales = "SELECT * FROM customer_events_raw" 
        ds_sales = get_or_create_dataset("v_sales_leads", sql=sql_sales)
        dash_sales = get_or_create_dashboard("Comercial - Vendas & Metas", "sales_overview")
        grant_access_to_dataset("ISP_Sales", ds_sales)

        # ---------------------------------------------------------
        # 3. Configurar Financeiro (Financial)
        # ---------------------------------------------------------
        # Simula View Financeira
        sql_fin = "SELECT * FROM customer_events_raw"
        ds_fin = get_or_create_dataset("v_financial_revenue", sql=sql_fin)
        dash_fin = get_or_create_dashboard("Financeiro - Faturamento", "finance_overview")
        grant_access_to_dataset("ISP_Financial", ds_fin)

        # ---------------------------------------------------------
        # 4. Configurar Suporte (Support)
        # ---------------------------------------------------------
        sql_sup = "SELECT * FROM customer_events_raw"
        ds_sup = get_or_create_dataset("v_support_tickets", sql=sql_sup)
        dash_sup = get_or_create_dashboard("Suporte - Atendimentos", "support_overview")
        grant_access_to_dataset("ISP_Support", ds_sup)

        # ---------------------------------------------------------
        # 5. Configurar Executivo (Executive)
        # ---------------------------------------------------------
        # Executivo vê TUDO. Damos acesso a todos os datasets criados acima.
        role_exec = "ISP_Executive"
        grant_access_to_dataset(role_exec, ds_noc)
        grant_access_to_dataset(role_exec, ds_sales)
        grant_access_to_dataset(role_exec, ds_fin)
        grant_access_to_dataset(role_exec, ds_sup)
        
        logger.info("Configuração de TODOS os perfis concluída com sucesso.")


if __name__ == "__main__":
    setup_assets()
