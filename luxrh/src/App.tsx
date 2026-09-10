import type { ReactNode } from 'react'
import { Navigate, Route, Routes } from 'react-router-dom'
import { useApp } from '@/context/AppContext'
import { AppShell } from '@/components/AppShell'
import { Loading } from '@/components/ui'

import Login from '@/pages/Login'
import CompanyPicker from '@/pages/CompanyPicker'
import Dashboard from '@/pages/Dashboard'
import Companies from '@/pages/Companies'
import CompanyDetail from '@/pages/CompanyDetail'
import Employees from '@/pages/Employees'
import EmployeeDetail from '@/pages/EmployeeDetail'
import Contracts from '@/pages/Contracts'
import ContractWizard from '@/pages/ContractWizard'
import ContractPreview from '@/pages/ContractPreview'
import Planning from '@/pages/Planning'
import ShiftTemplates from '@/pages/ShiftTemplates'
import TimeRegister from '@/pages/TimeRegister'
import Leave from '@/pages/Leave'
import SickLeave from '@/pages/SickLeave'
import Vigilance from '@/pages/Vigilance'
import DismissalSimulator from '@/pages/DismissalSimulator'
import Referential from '@/pages/Referential'
import CbaEditor from '@/pages/CbaEditor'
import Holidays from '@/pages/Holidays'
import Settings from '@/pages/Settings'
import SelfService from '@/pages/SelfService'

function Shell({ crumbs, children }: { crumbs: string[]; children: ReactNode }) {
  return <AppShell breadcrumb={crumbs}>{children}</AppShell>
}

export default function App() {
  const { session, authReady, isEmployeeOnly } = useApp()

  if (!authReady) {
    return (
      <div className="mx-auto max-w-md pt-24">
        <Loading label="Ouverture de la session…" />
      </div>
    )
  }

  if (!session) {
    return (
      <Routes>
        <Route path="*" element={<Login />} />
      </Routes>
    )
  }

  // Un salarié ne voit que son espace : le cloisonnement est aussi imposé en base.
  if (isEmployeeOnly) {
    return (
      <Routes>
        <Route path="/mon-espace/*" element={<SelfService />} />
        <Route path="*" element={<Navigate to="/mon-espace" replace />} />
      </Routes>
    )
  }

  return (
    <Routes>
      <Route path="/dossiers" element={<CompanyPicker />} />
      <Route path="/mon-espace/*" element={<SelfService />} />

      <Route path="/" element={<Shell crumbs={['Tableau de bord']}><Dashboard /></Shell>} />

      <Route path="/societes" element={<Shell crumbs={['Sociétés']}><Companies /></Shell>} />
      <Route path="/societes/:id" element={<Shell crumbs={['Sociétés', 'Fiche']}><CompanyDetail /></Shell>} />

      <Route path="/employes" element={<Shell crumbs={['Employés']}><Employees /></Shell>} />
      <Route path="/employes/:id" element={<Shell crumbs={['Employés', 'Fiche']}><EmployeeDetail /></Shell>} />

      <Route path="/contrats" element={<Shell crumbs={['Contrats']}><Contracts /></Shell>} />
      <Route path="/contrats/nouveau" element={<Shell crumbs={['Contrats', 'Assistant']}><ContractWizard /></Shell>} />
      <Route path="/contrats/:id" element={<Shell crumbs={['Contrats', 'Aperçu']}><ContractPreview /></Shell>} />

      <Route path="/planning" element={<Shell crumbs={['Planning']}><Planning /></Shell>} />
      <Route path="/planning/modeles" element={<Shell crumbs={['Planning', 'Modèles de shifts']}><ShiftTemplates /></Shell>} />
      <Route path="/planning/registre" element={<Shell crumbs={['Planning', 'Registre du temps']}><TimeRegister /></Shell>} />

      <Route path="/conges" element={<Shell crumbs={['Congés']}><Leave /></Shell>} />
      <Route path="/conges/maladies" element={<Shell crumbs={['Congés', 'Maladies']}><SickLeave /></Shell>} />

      <Route path="/vigilance" element={<Shell crumbs={['Vigilance']}><Vigilance /></Shell>} />
      <Route
        path="/vigilance/licenciement-collectif"
        element={<Shell crumbs={['Vigilance', 'Licenciement collectif']}><DismissalSimulator /></Shell>}
      />

      <Route path="/referentiel" element={<Shell crumbs={['Référentiel']}><Referential /></Shell>} />
      <Route path="/referentiel/cct" element={<Shell crumbs={['Référentiel', 'CCT']}><CbaEditor /></Shell>} />
      <Route path="/referentiel/feries" element={<Shell crumbs={['Référentiel', 'Jours fériés']}><Holidays /></Shell>} />

      <Route path="/parametres" element={<Shell crumbs={['Paramètres']}><Settings /></Shell>} />

      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  )
}
