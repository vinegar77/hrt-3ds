function love.conf(t)
  t.modules.physics=false
  if t.system then
  t.system.speedup=true
  end
  --t.console=true
end