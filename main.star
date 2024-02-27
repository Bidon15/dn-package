DEFAULT_NODE_STORE = "/opt/node-store"
DA_IMAGE = "ghcr.io/celestiaorg/celestia-node:v0.12.4"

def render_node_config(plan, args):
    config_file_template = read_file("./configs/config.toml.tmpl")
    da_node_config_file = plan.render_templates(
        name="light-node-configuration",
        config={
            "config.toml": struct(
                template=config_file_template,
                data={
                    "CORE_IP": args.get("core.ip"),
                    "CORE_RPC_PORT": args.get("core.rpc.port"),
                    "CORE_GRPC_PORT": args.get("core.grpc.port"),
                    "RPC_ADDRESS": args.get("rpc.addr"),
                    "RPC_PORT": args.get("rpc.port"),
                    "TRUSTED_HASH": args.get("headers.trusted-hash"),
                    "SAMPLE_FROM": args.get("daser.sample-from")
                }
            ),
        }
    )
    return da_node_config_file

def run(plan, args):
    P2P_NETWORK = args.get("p2p.network")

    results = plan.run_sh(
        run="whoami && celestia light init --p2p.network {0} --node.store=/home/celestia/node-store".format(P2P_NETWORK),
        image= "ghcr.io/celestiaorg/celestia-node:v0.12.4",
        store=[
            "/home/celestia/node-store/keys/*",
        ],
    )
    plan.print(results.files_artifacts)

    cfg_file = render_node_config(plan, args)

    plan.add_service(
    name = "celestia-light",
    config = ServiceConfig(
        image= "ghcr.io/celestiaorg/celestia-node:v0.12.4",
        ports = {
        "rpc": PortSpec(
                # The port number which we want to expose
                # MANDATORY
                number = 26658,

                # Transport protocol for the port (can be either "TCP" or "UDP")
                # Optional (DEFAULT:"TCP")
                transport_protocol = "TCP",

                # Application protocol for the port
                # Optional
                application_protocol = "http",
            ),
        },
        files={
            "/home/celestia/node-store/": cfg_file,
            "/home/celestia/node-store/keys": Directory(
                artifact_names=[results.files_artifacts[0]],
            ),
            "/home/celestia/node-store/data": Directory(
                persistent_key="data-directory"
            )
        },
        entrypoint=[
            "bash",
            "-c",
            "cat /home/celestia/node-store/config.toml && celestia light start --p2p.network {0} --node.store=/home/celestia/node-store".format(P2P_NETWORK),
        ],
        user = User(uid=0),
    ),
)