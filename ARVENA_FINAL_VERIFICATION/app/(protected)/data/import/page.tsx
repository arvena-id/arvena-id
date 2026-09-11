import { CommandForm } from "@/components/command-form";
import { ResourceList } from "@/components/resource-list";

export default function Page(){
  return <>
    <main className="page">
      <div className="page-head"><div><h1>Import data</h1><p>Buat import job, lalu lanjutkan mapping dan validasi tanpa melewati tenant/RLS boundary.</p></div></div>
      <CommandForm
        command="create_import_job"
        fields={[{name:"p_kind",label:"Jenis import",required:true,placeholder:"CUSTOMERS / ASSETS"}]}
        onSuccess="/data/import"
      />
    </main>
    <ResourceList resource="imports"/>
  </>;
}
