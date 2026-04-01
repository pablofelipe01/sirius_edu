export default function StatCard({ icon, value, label, color = 'green' }: {
  icon: string; value: string | number; label: string; color?: string;
}) {
  const bg = color === 'green' ? 'bg-green-50 text-green-600' :
             color === 'blue' ? 'bg-blue-50 text-blue-600' :
             color === 'orange' ? 'bg-orange-50 text-orange-600' :
             'bg-purple-50 text-purple-600'
  return (
    <div className="bg-white rounded-xl border border-gray-100 p-5">
      <div className="flex items-center gap-3 mb-2">
        <span className={`text-2xl p-2 rounded-lg ${bg}`}>{icon}</span>
      </div>
      <p className="text-2xl font-bold text-green-500">{value}</p>
      <p className="text-sm text-gray-500">{label}</p>
    </div>
  )
}
