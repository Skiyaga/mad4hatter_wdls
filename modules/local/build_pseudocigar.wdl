version 1.0

task build_pseudocigar {
    input {
        File alignments
        String output_suffix
        Int cpus = 1
        String docker_image
    }

    command <<<
        Rscript /opt/mad4hatter/bin/build_pseudocigar.R \
            --alignments ~{alignments} \
            --output_suffix ~{output_suffix} \
            --ncores ~{cpus}
    >>>

    output {
        File pseudocigar = "alignments.pseudocigar~{output_suffix}.txt"
    }

    runtime {
        docker: docker_image
        cpu: cpus
    }
}