## Quick Test

1. Run 
2. Add a property in your model (uncomment)  
`property dummyOrphaned: RawUtf8;`

3. Run (columns are created)
4. Comment out published property in model:  
`// property dummyOrphaned: RawUtf8;`
3. Restart
  - PrintDiffs → column shows as orphan
  - RunClean → column removed