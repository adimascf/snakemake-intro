configfile: 'config.yaml'

input_normal_1 = config["input"]["normal_read1"]
input_normal_2 = config["input"]["normal_read2"]
input_tumor_1 = config["input"]["tumor_read1"]
input_tumor_2 = config["input"]["tumor_read2"]


normal_json = config["output"]["json_file_normal"]
tumor_json = config["output"]["json_file_tumor"]


rule run_fastp_preprocessing:
    input:
        input_normal_r1 = input_normal_1,
        input_normal_r2 = input_normal_2,
        input_tumor_r1 = input_tumor_1,
        input_tumor_r2 = input_tumor_2

    output:
        output_normal_r1 = "processed_fqs/normal_fastped_1.fastq",
        output_normal_r2 = "processed_fqs/normal_fastped_2.fastq",
        output_tumor_r1 = "processed_fqs/tumor_fastped_1.fastq",
        output_tumor_r2 = "processed_fqs/tumor_fastped_2.fastq",
        normal_json = normal_json,
        tumor_json = tumor_json
    shell:
        """
        eval "$(conda shell.bash hook)" && conda activate quality_control &&
        mkdir -p processed_fqs && mkdir -p json_fastp &&
        fastp --in1 {input.input_normal_r1} --in2 {input.input_normal_r2} \
         --out1 {output.output_normal_r1} --out2 {output.output_normal_r2} \
         --json {output.normal_json} \
         --html normal.fastp.html &&

        fastp --in1 {input.input_tumor_r1} --in2 {input.input_tumor_r2} \
         --out1 {output.output_tumor_r1} --out2 {output.output_tumor_r2} \
         --json {output.tumor_json} \
         --html tumor.fastp.html
        """

rule run_multiqc:
    input:
        normal_json = normal_json,
        tumor_json = tumor_json
    output: "reports/multiqc_report.html"
    shell:
        """
        eval "$(conda shell.bash hook)" && conda activate quality_control &&
        mkdir -p reports &&
        multiqc --outdir reports json_fastp
        """

rule mapping_alignment:
    input:
        output_normal_r1 = "processed_fqs/normal_fastped_1.fastq",
        output_normal_r2 = "processed_fqs/normal_fastped_2.fastq",
        index_ref = "/home/adimascf/GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna"
    output:
        bam_normal = "bam/normal.bam"
    shell:
        """
        eval "$(conda shell.bash hook)" && conda activate bowtie2 &&
        mkdir -p bam &&
        bowtie2 -x {input.index_ref} -1 {input.output_normal_r1} -2 {input.output_normal_r2} |
        samtools view -S -b - > {output.bam_normal}
        """
