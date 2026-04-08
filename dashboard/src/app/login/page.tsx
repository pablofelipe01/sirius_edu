'use client'
import { useState } from 'react'
import { useRouter } from 'next/navigation'

export default function LoginPage() {
  const router = useRouter()
  const [nodeHex, setNodeHex] = useState('')
  const [pin, setPin] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  async function login(e: React.FormEvent) {
    e.preventDefault()
    setError('')
    setLoading(true)
    try {
      const res = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ node_hex: nodeHex.trim(), pin: pin.trim() }),
      })
      const data = await res.json()
      if (!res.ok) {
        setError(data.error || 'Error de login')
        setLoading(false)
        return
      }
      router.push('/')
      router.refresh()
    } catch {
      setError('Error de conexion')
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-green-50 to-blue-50 p-4">
      <div className="w-full max-w-md">
        <div className="text-center mb-8">
          <h1 className="text-3xl font-bold text-green-600">Sirius Edu</h1>
          <p className="text-gray-500 mt-1">Panel del Profesor</p>
        </div>

        <form onSubmit={login} className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 space-y-4">
          <div>
            <label htmlFor="node-hex" className="block text-sm font-medium text-gray-700 mb-1">
              ID de tu nodo Meshtastic
            </label>
            <input
              id="node-hex"
              type="text"
              value={nodeHex}
              onChange={e => setNodeHex(e.target.value)}
              placeholder="!49b7a524"
              autoFocus
              required
              className="w-full border border-gray-300 rounded-lg px-3 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-green-500"
            />
            <p className="text-xs text-gray-400 mt-1">El que aparece en tu dispositivo</p>
          </div>

          <div>
            <label htmlFor="pin" className="block text-sm font-medium text-gray-700 mb-1">
              PIN
            </label>
            <input
              id="pin"
              type="password"
              value={pin}
              onChange={e => setPin(e.target.value)}
              placeholder="••••"
              required
              maxLength={10}
              className="w-full border border-gray-300 rounded-lg px-3 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-green-500"
            />
          </div>

          {error && (
            <div className="bg-red-50 border border-red-100 text-red-600 text-sm rounded-lg px-3 py-2">
              {error}
            </div>
          )}

          <button
            type="submit"
            disabled={loading}
            className="w-full bg-green-600 text-white py-3 rounded-lg font-medium hover:bg-green-700 disabled:opacity-50 transition-colors"
          >
            {loading ? 'Verificando...' : 'Entrar'}
          </button>
        </form>

        <p className="text-center text-xs text-gray-400 mt-6">
          Solo profesores registrados pueden acceder
        </p>
      </div>
    </div>
  )
}
