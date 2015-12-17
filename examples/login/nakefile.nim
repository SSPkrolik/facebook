import nake

task defaultTask, "Run Facebook login example":
  when not defined(js):
    shell("nim", "c", "-r", "main.nim")
