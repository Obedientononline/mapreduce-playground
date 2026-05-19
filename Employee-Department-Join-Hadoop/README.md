# Employee-Department Data Integration - Hadoop Reducer-Side Join

![Hadoop](https://img.shields.io/badge/Apache%20Hadoop-3.4.1-66CCFF) ![Java](https://img.shields.io/badge/Java-17-orange) ![Join](https://img.shields.io/badge/Reducer--Side%20Join-MapReduce-blueviolet)

## Overview

Joins two separate CSV files (an employee table and a department table) on department ID using a Reducer-Side Join in Hadoop MapReduce. Both files are processed in parallel using MultipleInputs and joined entirely inside the cluster with no external database.

## Objective

- Load employee and department data from separate HDFS paths simultaneously
- Tag each record by source using MultipleInputs
- Join on shared DepartmentID key inside the Reducer
- Output enriched employee records with department name and location

## Real-World Use Case

| Scenario | Application |
|---|---|
| HR Systems | Enrich employee records with org structure |
| Payroll | Combine salary data with cost-centre info |
| Workforce Analytics | Analyse headcount by department and location |
| Data Integration | Join normalised tables without a relational DB |

## Technologies Used

| Technology | Version | Purpose |
|---|---|---|
| Apache Hadoop | 3.4.1 | Distributed processing |
| Java | 17 | MapReduce program |
| MultipleInputs API | 3.4.1 | Feed two files into one job |
| HDFS + YARN | 3.4.1 | Storage + scheduling |

## Architecture

```
+---------------------+    +----------------------+
|  employees.csv      |    |  departments.csv     |
|  (HDFS path 1)      |    |  (HDFS path 2)       |
+----------+----------+    +----------+-----------+
           |                          |
           v                          v
+------------------+      +----------------------+
|  EmployeeMapper  |      |  DepartmentMapper    |
|  Emit:           |      |  Emit:               |
|  (DeptID,        |      |  (DeptID,            |
|  "EMP:Alice")    |      |  "DEPT:Engineering") |
+----------+-------+      +-----------+----------+
           |                          |
           +------------+-------------+
                        | Shuffle & Sort by DeptID
                        v
           +------------------------+
           |  EmployeeDeptReducer   |
           |  Separate EMP: records |
           |  and DEPT: records     |
           |  Assemble joined row   |
           +------------------------+
                        |
                        v
     10   Engineering,Bangalore => Alice,60000
```

## Code Explanation

**EmployeeMapper**
```java
employeeData.set("EMP:" + empId + "," + empName + "," + salary);
context.write(deptId, employeeData); // key = DeptID
```
Tags each employee record with the `EMP:` prefix before emitting.

**DepartmentMapper**
```java
departmentData.set("DEPT:" + deptName + "," + location);
context.write(deptId, departmentData); // same key = DeptID
```
Tags each department record with the `DEPT:` prefix.

**Reducer**
```java
for (Text val : values) {
    if (record.startsWith("DEPT:")) departmentInfo = record.substring(5);
    else if (record.startsWith("EMP:")) employeeList.append(record.substring(4));
}
result.set(departmentInfo + " => " + employeeList);
context.write(key, result);
```
Both sources arrive at the same reducer key, are separated by prefix, then merged into one output row.

## Run

```bash
javac -classpath $(hadoop classpath) ReducerSideJoin.java
jar cf rsj.jar red*.class

hdfs dfs -mkdir -p /input/rsj
hdfs dfs -put employees.csv /input/rsj/emp/
hdfs dfs -put departments.csv /input/rsj/dept/

hadoop jar rsj.jar red /input/rsj/emp /input/rsj/dept /output/rsj

hdfs dfs -cat /output/rsj/part-r-00000
```

## Sample Output

```
10    Engineering,Bangalore => 1,Alice,60000 | 2,Bob,72000
20    Marketing,Mumbai => 3,Carol,55000
30    Finance,Chennai => 4,David,68000
```

## Scalability

| Scale | Approach |
|---|---|
| Small tables | Single-node, works as-is |
| Large employee table | Increase reducers, partition by DeptID range |
| Very large both tables | Switch to Spark DataFrame join |
