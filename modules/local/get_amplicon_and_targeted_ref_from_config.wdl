version 1.0

# Print given message to stderr and return an error
task get_amplicon_and_targeted_ref_from_config {
    input {
        Array[String] pools
        String docker_image
        String pool_options_json = "/opt/mad4hatter/conf/terra_panel.json" # located on docker
    }

    command <<<
        set -euo pipefail
        set -x

        python3 <<CODE

        import json
        import logging
        import shutil
        import os

        logging.basicConfig(level=logging.INFO)

        logging.info("Loading pool configuration from JSON")
        with open("~{pool_options_json}") as f:
            pool_config = json.load(f)

        amplicon_info_paths = []
        targeted_reference_paths = []
        missing_pools = []

        logging.info("Processing requested pools: ~{sep=',' pools}")

        pool_name_mapping = {
            '1A': 'D1.1',
            '1B': 'R1.1',
            '2' : 'R2.1',
            '5' : 'R1.2', 
            'D1' : 'D1.1',
            'R1' : 'R1.2',
            'R2' : 'R2.1',
            'M1' : 'M1.1',
            'M2' : 'M2.1',
        }

        updated_pool_names = []
        for pool in "~{sep=',' pools}".split(","):
            if pool in pool_config['pool_options']:
                amplicon_info_paths.append(pool_config['pool_options'][pool]["amplicon_info_path"])
                targeted_reference_paths.append(pool_config['pool_options'][pool]["targeted_reference_path"])
                if pool in pool_name_mapping: 
                    updated_pool_names.append(pool_name_mapping[pool])
                else: 
                    updated_pool_names.append(pool)
            else:
                missing_pools.append(pool)
        if missing_pools:
            raise ValueError(f"Pools were not found in configuration: {', '.join(missing_pools)}. `--amplicon_info` and, if running Mad4Hatter or Mad4hatterPostProcessing, either `--refseq_fasta` or `--genome` must be provided when using bespoke pools.")

        logging.info("Copying amplicon info and targeted reference files to output directories")
        os.makedirs("amplicon_info_files", exist_ok=True)
        os.makedirs("targeted_reference_files", exist_ok=True)
        for amplicon_file in amplicon_info_paths:
            shutil.copy2(amplicon_file, "amplicon_info_files/")
        for reference_file in targeted_reference_paths:
            shutil.copy2(reference_file, "targeted_reference_files/")
        
        logging.info("Writing updated pool names to output file")
        with open("updated_pool_names.txt", "w") as f:
            for pool_name in updated_pool_names:
                f.write(pool_name + "\n")
        CODE
    >>>

    output {
        Array[File] amplicon_info_files = glob("amplicon_info_files/*")
        Array[File] targeted_reference_files = glob("targeted_reference_files/*")
        Array[String] updated_pool_names = read_lines("updated_pool_names.txt")
    }

    runtime {
        docker: docker_image
    }
}