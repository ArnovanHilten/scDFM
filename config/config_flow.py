
from dataclasses import dataclass
import hashlib
import json
import os
@dataclass
class FlowConfig:
    # Flow model type
    model_type: str = 'hierarchical'

    # Flow Matching specific parameters
    batch_size: int = 32
    ntoken: int = 512
    d_model: int = 512
    lr: float = 1e-5
    steps: int = 5000
    eta_min: float = 1e-7
    devices: str = "1"
    test_only: bool = False
    # Perturbation related parameters
    data_name: str = "combosciplex"
    perturbation_function: str = 'crisper' 
    noise_type: str = "Gaussian"
    poisson_alpha: float = 0.8
    poisson_target_sum: int = -1

    print_every: int = 5000
    mode: str = 'predict_y' # predict_y, predict_p
    result_path: str = './result'
    perturbation_fusion_method: str = 'sum' # mlp, sum
    fusion_method: str = 'cross' # cross , concat, add
    infer_top_gene: int = 1000
    n_top_genes: int = 5000
    checkpoint_path: str = ''
    gamma: float = 0.0
    split_method: str = 'additive'
    use_mmd_loss: bool = False
    fold: int = 0
    use_negative_edge: bool = False
    topk: int = 15
    
    # Generic dataset support (STATE-prepared h5ad files)
    data_path: str = './data'             # directory containing <data_name>.h5ad
    condition_col: str = 'gene'           # obs column holding perturbation labels
    control_value: str = 'non-targeting'  # value in condition_col meaning "unperturbed"
    preprocessed: bool = True             # True = X is already log1p-normalized; skip normalization
    split_toml: str = ''                  # path to STATE toml; if set, use its fewshot test list instead of random split
    run_id: str = ''                      # optional human label (e.g. "run01"); overrides auto name when set

    # Weights & Biases
    wandb_project: str = ''              # W&B project name; leave empty to disable W&B
    wandb_entity: str = ''              # W&B entity (team / username)
    wandb_name: str = ''                # run display name; defaults to result folder name
    wandb_tags: str = ''                # comma-separated tags e.g. "scdfm,baseline,fold0"

    def __post_init__(self):
        if self.data_name == 'norman_umi_go_filtered':
            self.n_top_genes = 5054
        elif self.data_name == 'norman':
            self.n_top_genes = 5000
        path = self.make_path()

    def make_path(self):
        # Short hash of the parameters that actually affect model behaviour
        key = {
            'data_name': self.data_name,
            'model_type': self.model_type,
            'fusion_method': self.fusion_method,
            'd_model': self.d_model,
            'lr': self.lr,
            'fold': self.fold,
            'n_top_genes': self.n_top_genes,
            'perturbation_function': self.perturbation_function,
            'split_method': self.split_method,
            'split_toml': os.path.basename(self.split_toml),
            'mode': self.mode,
        }
        h = hashlib.md5(json.dumps(key, sort_keys=True).encode()).hexdigest()[:8]
        if self.run_id:
            name = f'{self.run_id}_{self.data_name}_fold{self.fold}'
        else:
            name = f'{self.data_name}_fold{self.fold}_{h}'
        return os.path.join(self.result_path, name)