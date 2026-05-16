import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.conf.Configured;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
import org.apache.hadoop.util.Tool;
import org.apache.hadoop.util.ToolRunner;
import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.net.URI;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class MSJ extends Configured implements Tool {

    static class ZoneInfo {
        final String borough;
        final String zone;
        final String serviceZone;
        ZoneInfo(String borough, String zone, String serviceZone) {
            this.borough = borough;
            this.zone = zone;
            this.serviceZone = serviceZone;
        }
    }

    private static final int COL_PICKUP_DT = 1;
    private static final int COL_DISTANCE  = 4;
    private static final int COL_PU_LOC    = 5;
    private static final int COL_DO_LOC    = 6;
    private static final int COL_FARE      = 10;
    private static final int COL_TIP       = 13;
    private static final int COL_TOTAL     = 16;

    public static class TripEnrichmentMapper extends Mapper<LongWritable, Text, Text, Text> {

        private final Map<String, ZoneInfo> zoneMap = new HashMap<>();

        @Override
        protected void setup(Context context) throws IOException, InterruptedException {
            URI[] cacheFiles = context.getCacheFiles();
            if (cacheFiles == null || cacheFiles.length == 0)
                throw new IOException("Distributed Cache is empty! Zone file not found.");
            for (URI uri : cacheFiles) {
                String alias = uri.getFragment();
                String name = (alias != null) ? alias : uri.getPath();
                if (name.contains("taxi_zone_lookup")) loadZoneLookup(name);
            }
            System.out.printf("[Mapper Setup] Loaded %d zones into memory.%n", zoneMap.size());
        }

        private void loadZoneLookup(String filePath) throws IOException {
            try (BufferedReader br = new BufferedReader(new FileReader(filePath))) {
                String line;
                boolean header = true;
                while ((line = br.readLine()) != null) {
                    if (header) { header = false; continue; }
                    line = line.trim();
                    if (line.isEmpty()) continue;
                    String[] cols = line.split(",", 4);
                    if (cols.length < 4) continue;
                    zoneMap.put(cols[0].trim(), new ZoneInfo(cols[1].trim(), cols[2].trim(), cols[3].trim()));
                }
            }
        }

        @Override
        protected void map(LongWritable offset, Text value, Context context)
                throws IOException, InterruptedException {
            String line = value.toString().trim();
            if (line.startsWith("VendorID") || line.isEmpty()) return;
            String[] cols = splitCSV(line);
            if (cols.length <= COL_TOTAL) {
                context.getCounter("NYCTaxi", "MALFORMED_ROWS").increment(1);
                return;
            }
            try {
                String pickupDt = cols[COL_PICKUP_DT].trim();
                String date  = pickupDt.split(" ")[0];
                String hour  = pickupDt.split(" ")[1].substring(0, 2) + ":00";
                String puLocId = cols[COL_PU_LOC].trim();
                String doLocId = cols[COL_DO_LOC].trim();
                ZoneInfo puZone = zoneMap.getOrDefault(puLocId, new ZoneInfo("Unknown", "Unknown Zone", "Unknown"));
                ZoneInfo doZone = zoneMap.getOrDefault(doLocId, new ZoneInfo("Unknown", "Unknown Zone", "Unknown"));
                String outKey = date + " | " + puZone.borough;
                String outVal = String.join(",",
                        date, hour,
                        puLocId, puZone.zone, puZone.borough, puZone.serviceZone,
                        doLocId, doZone.zone, doZone.borough, doZone.serviceZone,
                        cols[COL_DISTANCE].trim(), cols[COL_FARE].trim(), cols[COL_TIP].trim(), cols[COL_TOTAL].trim());
                context.write(new Text(outKey), new Text(outVal));
                context.getCounter("NYCTaxi", "TRIPS_JOINED").increment(1);
            } catch (Exception e) {
                context.getCounter("NYCTaxi", "PARSE_ERRORS").increment(1);
            }
        }

        private String[] splitCSV(String line) {
            List<String> result = new ArrayList<>();
            StringBuilder sb = new StringBuilder();
            boolean inQuotes = false;
            for (char c : line.toCharArray()) {
                if (c == '"') inQuotes = !inQuotes;
                else if (c == ',' && !inQuotes) { result.add(sb.toString()); sb.setLength(0); }
                else sb.append(c);
            }
            result.add(sb.toString());
            return result.toArray(new String[0]);
        }
    }

    @Override
    public int run(String[] args) throws Exception {
        String zoneLookupPath = "hdfs:///assignmentinput/msj/taxi_zone_lookup.csv";
        String tripInputPath  = "hdfs:///assignmentinput/msj";
        String outputPath     = "hdfs:///assignmentoutput/msj";
        Configuration conf = getConf();
        Job job = Job.getInstance(conf, "Map-Side Join: NYC Taxi Trips + Zone Lookup");
        job.setJarByClass(MSJ.class);
        job.setMapperClass(TripEnrichmentMapper.class);
        job.setNumReduceTasks(0);
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(Text.class);
        job.addCacheFile(new URI(zoneLookupPath + "#taxi_zone_lookup"));
        FileInputFormat.addInputPath(job, new Path(tripInputPath));
        FileOutputFormat.setOutputPath(job, new Path(outputPath));
        boolean success = job.waitForCompletion(true);
        if (success) {
            System.out.printf("Trips Joined   : %,d%n", job.getCounters().findCounter("NYCTaxi", "TRIPS_JOINED").getValue());
            System.out.printf("Malformed Rows : %,d%n", job.getCounters().findCounter("NYCTaxi", "MALFORMED_ROWS").getValue());
            System.out.printf("Parse Errors   : %,d%n", job.getCounters().findCounter("NYCTaxi", "PARSE_ERRORS").getValue());
        }
        return success ? 0 : 1;
    }

    public static void main(String[] args) throws Exception {
        System.exit(ToolRunner.run(new MSJ(), args));
    }
}
