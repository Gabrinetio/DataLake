import logging
from superset.app import create_app
from superset.extensions import security_manager
from superset import db

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("ISP_Roles")

def create_isp_roles():
    app = create_app()
    with app.app_context():
        logger.info("Conectando ao SecurityManager do Superset...")
        
        # Definição das Roles e suas descrições
        roles_to_create = {
            "ISP_Executive": "Acesso total a dashboards de negócio (Financeiro, Comercial, Executivo).",
            "ISP_NOC": "Acesso a dashboards técnicos, telemetria e engenharia de rede.",
            "ISP_Support": "Acesso a dados de atendimento e qualidade de experiência do cliente.",
            "ISP_Sales": "Acesso a mapas de vendas, viabilidade e metas comerciais.",
            "ISP_Financial": "Acesso a dados de faturamento, inadimplência e fluxo de caixa."
        }
        
        # Permissões base (Gamma é view-only)
        gamma_role = security_manager.find_role("Gamma")
        
        if not gamma_role:
            logger.warning("Role 'Gamma' não encontrada. As novas roles estarao vazias.")
        
        for role_name, description in roles_to_create.items():
            existing_role = security_manager.find_role(role_name)
            
            if not existing_role:
                logger.info(f"Criando role: {role_name}...")
                new_role = security_manager.add_role(role_name)
                
                # Copiar permissões do Gamma para começar
                if gamma_role:
                    for perm in gamma_role.permissions:
                         if perm not in new_role.permissions:
                            new_role.permissions.append(perm)
                
                # Commit via db.session (SQLAlchemy)
                db.session.commit()
                logger.info(f"Role '{role_name}' criada com sucesso.")
            else:
                logger.info(f"Role '{role_name}' já existe. Pulando.")

        logger.info("Processo de criação de perfis finalizado.")

if __name__ == "__main__":
    create_isp_roles()
