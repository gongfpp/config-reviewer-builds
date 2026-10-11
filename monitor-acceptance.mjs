// Observability only: no credentials, process arguments or private source are printed.
import { execFileSync } from 'node:child_process';
import { appendFileSync, mkdirSync } from 'node:fs';
const folder = 'C:/ReviewerKit/artifacts/dev-kit-test';
mkdirSync(folder, { recursive: true });
function sample() {
  try {
    const output = execFileSync('C:/Windows/System32/WindowsPowerShell/v1.0/powershell.exe', ['-NoProfile','-Command', "Get-Process | Where-Object { $_.ProcessName -in @('rustc','cargo','cl','link','node','msiexec','vs_setup','setup','config-reviewer') } | Select-Object ProcessName,Id,CPU,WorkingSet64,@{n='AgeSeconds';e={[int]((Get-Date)-$_.StartTime).TotalSeconds}} | ConvertTo-Json -Compress"], { encoding: 'utf8', timeout: 15000 });
    const record = JSON.stringify({ time: new Date().toISOString(), processes: output.trim() });
    appendFileSync(`${folder}/process-monitor.jsonl`, record + '\n');
    console.log('Acceptance process status:', record);
  } catch (error) {
    const record = JSON.stringify({ time: new Date().toISOString(), status: error.status, processes: error.stdout?.toString(), error: error.stderr?.toString() || error.message });
    appendFileSync(`${folder}/process-monitor.jsonl`, record + '\n');
    console.log('Acceptance process status:', record);
  }
}
sample();setInterval(sample, 60000);
