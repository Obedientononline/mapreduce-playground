import java.io.IOException;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.mapreduce.lib.input.MultipleInputs;
import org.apache.hadoop.mapreduce.lib.input.TextInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;

public class red {

    public static class EmployeeMapper extends Mapper<Object, Text, IntWritable, Text> {

        private IntWritable deptId = new IntWritable();
        private Text employeeData = new Text();

        public void map(Object key, Text value, Context context)
                throws IOException, InterruptedException {
            String line = value.toString();
            String[] fields = line.split(",");
            if (fields.length == 4) {
                String empId = fields[0].trim();
                String empName = fields[1].trim();
                String salary = fields[2].trim();
                int departmentId = Integer.parseInt(fields[3].trim());
                deptId.set(departmentId);
                employeeData.set("EMP:" + empId + "," + empName + "," + salary);
                context.write(deptId, employeeData);
            }
        }
    }

    public static class DepartmentMapper extends Mapper<Object, Text, IntWritable, Text> {

        private IntWritable deptId = new IntWritable();
        private Text departmentData = new Text();

        public void map(Object key, Text value, Context context)
                throws IOException, InterruptedException {
            String line = value.toString();
            String[] fields = line.split(",");
            if (fields.length == 3) {
                int departmentId = Integer.parseInt(fields[0].trim());
                String deptName = fields[1].trim();
                String location = fields[2].trim();
                deptId.set(departmentId);
                departmentData.set("DEPT:" + deptName + "," + location);
                context.write(deptId, departmentData);
            }
        }
    }

    public static class EmployeeDeptReducer extends Reducer<IntWritable, Text, IntWritable, Text> {

        private Text result = new Text();

        @Override
        public void reduce(IntWritable key, Iterable<Text> values, Context context)
                throws IOException, InterruptedException {
            String departmentInfo = "";
            StringBuilder employeeList = new StringBuilder();

            for (Text val : values) {
                String record = val.toString();
                if (record.startsWith("DEPT:")) {
                    departmentInfo = record.substring(5);
                } else if (record.startsWith("EMP:")) {
                    String empInfo = record.substring(4);
                    if (employeeList.length() > 0) employeeList.append(" | ");
                    employeeList.append(empInfo);
                }
            }

            if (departmentInfo.length() > 0 && employeeList.length() > 0) {
                result.set(departmentInfo + " => " + employeeList.toString());
            } else if (employeeList.length() > 0) {
                result.set("NO_DEPT => " + employeeList.toString());
            } else if (departmentInfo.length() > 0) {
                result.set(departmentInfo + " => NO_EMPLOYEES");
            }
            context.write(key, result);
        }
    }

    public static void main(String[] args) throws Exception {
        if (args.length != 3) {
            System.err.println("Usage: EmployeeDepartmentJoin <employee_input> <department_input> <output>");
            System.exit(-1);
        }
        Configuration conf = new Configuration();
        Job job = Job.getInstance(conf, "Employee-Department Join");
        job.setJarByClass(red.class);
        job.setReducerClass(EmployeeDeptReducer.class);
        job.setOutputKeyClass(IntWritable.class);
        job.setOutputValueClass(Text.class);
        MultipleInputs.addInputPath(job, new Path(args[0]), TextInputFormat.class, EmployeeMapper.class);
        MultipleInputs.addInputPath(job, new Path(args[1]), TextInputFormat.class, DepartmentMapper.class);
        FileOutputFormat.setOutputPath(job, new Path(args[2]));
        System.exit(job.waitForCompletion(true) ? 0 : 1);
    }
}
