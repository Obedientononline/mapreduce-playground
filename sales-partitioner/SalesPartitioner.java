import java.io.IOException;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.input.TextInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
import org.apache.hadoop.mapreduce.lib.output.TextOutputFormat;

public class wordcount {

    public static class wordmapper extends Mapper<LongWritable, Text, Text, IntWritable> {

        Text itemKey = new Text();
        IntWritable salesValue = new IntWritable();

        public void map(LongWritable key, Text value, Context context)
                throws IOException, InterruptedException {
            String line = value.toString();
            String[] colvalue = line.split(",");
            if (colvalue.length < 2 || colvalue[0].equals("Item")) {
                return; // skip header or malformed lines
            }
            try {
                String item = colvalue[0];
                itemKey.set(item);
                int amount = Integer.parseInt(colvalue[1].trim());
                salesValue.set(amount);
                context.write(itemKey, salesValue);
            } catch (NumberFormatException e) {
                // skip unparseable rows
            }
        }
    }

    public static class wordreducer extends Reducer<Text, IntWritable, Text, IntWritable> {

        public void reduce(Text key, Iterable<IntWritable> values, Context context)
                throws IOException, InterruptedException {
            int total = 0;
            for (IntWritable val : values) {
                total += val.get();
            }
            context.write(new Text(key), new IntWritable(total));
        }
    }

    public static void main(String[] args) throws Exception {
        Configuration conf = new Configuration();
        @SuppressWarnings("deprecation")
        Job job = new Job(conf, "salescalc");
        job.setJarByClass(wordcount.class);
        job.setOutputFormatClass(TextOutputFormat.class);
        job.setInputFormatClass(TextInputFormat.class);
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(IntWritable.class);
        job.setMapperClass(wordmapper.class);
        job.setReducerClass(wordreducer.class);
        job.setNumReduceTasks(1);
        FileInputFormat.setInputPaths(job, new Path(args[0]));
        FileOutputFormat.setOutputPath(job, new Path(args[1]));
        boolean success = job.waitForCompletion(true);
        System.out.println(success);
    }
}
