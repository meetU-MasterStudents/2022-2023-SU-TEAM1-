#!/bin/bash
#
#SBATCH -p gpu
#SBATCH --account=2233_meetu
#SBATCH --mem-per-cpu=20GB
#SBATCH --gres gpu:7g.40gb:1
#SBATCH -o ./logs/slurm.diffdock.%N.%j.out
#SBATCH -e ./logs/slurm.diffdock.%N.%j.err

PROJECT_DIR='/shared/projects/2233_meetu/bddes'
DIFFDOCK_DIR="$PROJECT_DIR/DiffDock"
DATA_DIR="$PROJECT_DIR/data"
ESM_WEIGHTS_DIR="$DIFFDOCK_DIR/ems/model_weights"
OUT_DIR="$DATA_DIR/diffdock_out/ATP_ideal"

#LIGAND_LIBRARY="$PROJECT_DIR/data/ligand-db_1207/pilot_library.sdf"
TEST_LIGAND="$DATA_DIR/ATP_ideal.sdf"
TEST_PROTEIN="$DATA_DIR/nsp13/7nio_ok.pdb"
FASTA_PROTEIN="$DATA_DIR/prepared_for_esm.fasta"
ESM_OUT="$DIFFDOCK_DIR/data/esm2_output"
ESM_MODEL=esm2_t33_650M_UR50D

date=$(date +'%F %T')
echo "#######################################################################"
echo "[$date] diffdock.sh"
echo "#######################################################################"

echo "prepping FASTA file from PDB file for embedding generation using file:"
echo "$TEST_PROTEIN"
python $DIFFDOCK_DIR/datasets/esm_embedding_preparation.py --protein_path $TEST_PROTEIN --out_file $FASTA_PROTEIN

echo "generating ESM embedding"
python $DIFFDOCK_DIR/esm/scripts/extract.py \
    --repr_layers 33 \
    --include per_tok \
    --truncation_seq_length 4096 \
    $ESM_MODEL $FASTA_PROTEIN $ESM_OUT

echo "inference using DiffDock, with following dir as output dir:"
echo $OUT_DIR
python $DIFFDOCK_DIR/inference.py \
    --protein_path $TEST_PROTEIN \
    --ligand $TEST_LIGAND \
    --out_dir $OUT_DIR \
    --model_dir "$DIFFDOCK_DIR/workdir/paper_score_model" \
    --confidence_model_dir "$DIFFDOCK_DIR/workdir/paper_confidence_model" \
    --esm_embeddings_path $ESM_OUT \
    --inference_steps 20 --samples_per_complex 40 --batch_size 10 --actual_steps 18 --no_final_step_noise

end_date=$(date +'%F %T')
echo "#######################################################################"
echo "[$end_date] script termination"
echo "#######################################################################"
