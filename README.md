# oracle-devops-portfolio

Clúster **Kubernetes** en **Oracle Cloud Free Tier** con un flujo
**GitOps** completo, autoalojado de principio a fin: infraestructura
como código, CI/CD, despliegue continuo sin intervención manual y
observabilidad.

## Objetivo del proyecto

Montar un clúster de Kubernetes real, de varios nodos, con un
pipeline GitOps completo y autoalojado — sin depender de ningún
servicio gestionado de terceros salvo Cloudflare para el borde de
red. El clúster aloja varias cargas de trabajo reales: una
aplicación de música personal, la web de un negocio real, y una
instancia de Odoo de uso propio — cada una desplegada y actualizada
automáticamente a través de ArgoCD.

## Arquitectura

```
                         Tu equipo (WSL)
                                │
                          git push
                                ▼
                ┌───────────────────────────┐
                │   Gitea (Git + Actions +    │
                │   registro de contenedores)  │
                └───────────────────────────┘
                                │
                     build · push a registro
                                │
                                ▼
                ┌───────────────────────────┐
                │           ArgoCD             │
                │   (sincroniza el clúster      │
                │    automáticamente)           │
                └───────────────────────────┘
                                │
                                ▼
        ┌─────────────────────────────────────────┐
        │        Clúster k3s (2 nodos, Oracle)        │
        │                                              │
        │   control-plane          worker               │
        │   (Odoo + PostgreSQL)   (Riddim, Tasema,       │
        │                          Gitea, Prometheus,      │
        │                          Grafana)                │
        └─────────────────────────────────────────┘
                                │
                       Cloudflare Tunnel
                                │
                                ▼
                            Internet
```

Ningún nodo tiene un puerto de entrada publicado ni IP pública — la
administración se hace sobre una red privada de Tailscale, y el
único tráfico público entra a través de túneles de Cloudflare que la
propia VM inicia hacia fuera, nunca al revés.

**Sobre el reparto de cargas entre nodos**: la práctica recomendada
en un clúster de Kubernetes real es mantener el `control-plane` sin
ninguna carga de aplicación, para no arriesgar la estabilidad del
API server. Aquí se incumple deliberadamente: al comprobar con
Prometheus/Grafana que `worker` no tenía margen de memoria
suficiente para sumar Odoo + PostgreSQL, se desplegaron en
`control-plane` en su lugar, aprovechando la RAM disponible del
nivel gratuito de Oracle en un proyecto personal de bajo riesgo. No
es la decisión que se tomaría en un clúster de producción — ahí la
solución correcta sería añadir capacidad al `worker` o sumar un
tercer nodo — pero es una decisión consciente y documentada, no un
descuido, y encaja con las restricciones reales de este proyecto.

## Conocimientos de Oracle Cloud e infraestructura aplicados

- **Terraform**: infraestructura como código sobre OCI (Oracle Cloud
  Infrastructure) con backend remoto en Object Storage
  (compatible S3), red privada sin IP pública en ningún nodo.
- **Ansible**: configuración idempotente del sistema operativo de
  cada VM — dependencias, firewall restringido a la red de
  Tailscale, memoria de intercambio (swap) añadida tras un análisis
  real de presión de memoria con Prometheus.
- **Tailscale**: red privada de administración, sin exponer SSH ni
  ningún otro puerto a internet.
- **k3s**: clúster de Kubernetes de 2 nodos.

## Competencias técnicas aplicadas

- **GitOps real**: Gitea (Git + Actions autoalojados) + ArgoCD, con
  `syncPolicy.automated` (`prune` y `selfHeal`) activo en todas las
  aplicaciones — cualquier cambio manual sobre el clúster se
  revierte al estado que describe el repositorio correspondiente.
- **Separación de responsabilidades**: el punto de edición de código
  vive en el equipo del desarrollador, nunca en la máquina de
  producción.
- **Gestión de secretos**: contraseñas y tokens siempre en
  Kubernetes Secrets, nunca en manifiestos ni en el propio
  repositorio; tokens con permisos mínimos en vez de credenciales de
  administrador para cualquier automatización.
- **Observabilidad real**: Prometheus + Grafana, usados para tomar
  decisiones de arquitectura basadas en datos (ubicación de cargas,
  necesidad de memoria de intercambio) en vez de suposiciones.
- **Copias de seguridad automatizadas**: `CronJob` de Kubernetes que
  respalda periódicamente el código fuente en Object Storage, con
  credenciales de solo lectura.

## Estructura del repositorio

```
terraform/    Infraestructura como código (VMs, red, backend remoto)
ansible/      Configuración del sistema operativo de cada nodo
k8s/
  gitea/          Git, CI/CD y registro de contenedores autoalojados
  argocd/         Definiciones de Application (GitOps)
  observability/  Prometheus + Grafana
  backups/        CronJob de copias de seguridad
  riddim/         Manifiestos de la app de música personal
  odoo/           Manifiestos de la instancia de Odoo
```

Los archivos con datos específicos de la instancia (IPs de la red
privada, nombre del namespace de Object Storage) se excluyen del
repositorio; se incluyen sus equivalentes `.example` con la
estructura completa, sin los valores reales.
