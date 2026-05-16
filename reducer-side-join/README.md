# reducer-side-join

Joins two CSV files — employees and departments — on department ID using a Reducer-Side Join in Hadoop MapReduce.

Both files are fed into separate Mappers via `MultipleInputs`. Records are tagged (EMP: / DEPT:) so the Reducer knows which source each value came from, then joined on the shared key.

## Files

- `ReducerSideJoin.java` — EmployeeMapper, DepartmentMapper, EmployeeDeptReducer

## Datasets

**employees.csv**
```
EmpID, Name, Salary, DeptID
1, Alice, 60000, 10
2, Bob, 55000, 20
```

**departments.csv**
```
DeptID, DeptName, Location
10, Engineering, Bangalore
20, Marketing, Mumbai
```

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

## Output

```
10    Engineering,Bangalore => 1,Alice,60000
20    Marketing,Mumbai => 2,Bob,55000
```
