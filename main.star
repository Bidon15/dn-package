DEFAULT_NODE_STORE = "/opt/node-store"
DA_IMAGE = "ghcr.io/celestiaorg/celestia-node:v0.12.4"

def init_node(plan, args):
    node_store_path = args.get("node.store") or DEFAULT_NODE_STORE

    # Use node_store_path for further processing
    plan.print("Using node store path: " + node_store_path)

    if node_store_path:
        plan.print("Node store is not empty, skipping node initialization")
        return False
    else:
        plan.print("Node store is empty, initializing node")

        return True

def render_node_config(plan, args):
    config_file_template = read_file("./configs/light-config.toml.tmpl")
    da_node_config_file = plan.render_templates(
        name="light-node-configuration",
        config={
            "config.toml": struct(
                template=config_file_template,
                data={
                    "CORE_IP": args.get("core.ip"),
                    "CORE_RPC_PORT": args.get("core.rpc.port"),
                    "CORE_GRPC_PORT": args.get("core.grpc.port"),
                    "RPC_ADDRESS": args.get("rpc.address"),
                    "RPC_PORT": args.get("rpc.port"),
                }
            ),
        }
    )
    return da_node_config_file

def run(plan, args):
    results = plan.run_sh(
        run="whoami && celestia light init --node.store=/home/celestia/.celestia-light",
        image= "ghcr.io/celestiaorg/celestia-node:v0.12.4",
        store=[
            "/home/celestia/.celestia-light/*"
        ],
    )
    plan.print(results.files_artifacts)

    plan.add_service(
    name = "celestia-light",
    config = ServiceConfig(
        image= "ghcr.io/celestiaorg/celestia-node:v0.12.4",
        env_vars = {
            "NODE_TYPE": "light",
            "P2P_NETWORK": "celestia",
            "NODE_STORE": "/home/celestia/.celestia-light",
        },
        files={
            "/home/celestia/.celestia-light": Directory(
                artifact_names=[results.files_artifacts[0]],
            )
        },
        entrypoint=[
            "bash",
            "-c",
            "celestia light start --node.store=/home/celestia/.celestia-light",
        ],
        user = User(uid=0),
    ),
)