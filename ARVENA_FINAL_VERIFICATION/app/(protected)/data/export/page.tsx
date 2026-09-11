import { CommandForm } from "@/components/command-form";
import { ResourceList } from "@/components/resource-list";

export default function Page(){
  return <>
    <main className="page">
      <div className="page-head"><div><h1>Export data</h1><p>Buat export job untuk dataset yang diizinkan. Hasil tetap mengikuti permission dan organisasi aktif.</p></div></div>
      <CommandForm
        command="create_export_job"
        fields={[
          {name:"p_dataset",label:"Dataset",required:true,placeholder:"CUSTOMERS / JOBS / INVOICES / PAYMENTS"},
          {name:"p_filter",label:"Filter JSON",placeholder:"{}"}
        ]}
        defaults={{p_filter:"{}"}}
        onSuccess="/data/export"
      />
    </main>
    <ResourceList resource="exports"/>
  </>;
}
