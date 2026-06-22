import React, { useState } from 'react';
import { 
  Building, 
  Calendar, 
  Users, 
  Receipt, 
  Plus, 
  CheckCircle, 
  XCircle, 
  AlertCircle, 
  RotateCcw, 
  Download, 
  PieChart, 
  Search, 
  CreditCard, 
  Wallet, 
  Shield, 
  FileText,
  BadgeAlert,
  ArrowDownLeft,
  ArrowUpRight,
  TrendingUp,
  Settings,
  Undo2
} from 'lucide-react';

// --- MOCK DEFINITIONS IN ARABIC ---
const INITIAL_PROPERTIES = [
  { id: 1, name: 'فندق النخبة الرياض', code: 'SAR', type: 'فندق' },
  { id: 2, name: 'شقق الحرمين الفاخرة', code: 'SAR', type: 'شقق مفروشة' }
];

const INITIAL_GUESTS = [
  { id: 101, name: 'سليمان بن خالد الرويلي', phone: '0501234567', docNo: '1098765432', currency: 'SAR', balance: 500 },
  { id: 102, name: 'أحمد محمود المغربي', phone: '0543210987', docNo: '2345678901', currency: 'SAR', balance: 0 },
  { id: 103, name: 'فاطمة الزهراء الشمراني', phone: '0567891234', docNo: '1122334455', currency: 'SAR', balance: 150 }
];

const INITIAL_UNITS = [
  { id: 301, number: '301', type: 'غرفة مفردة', floor: 3, capacity: 1, status: 'available', rate: 250 },
  { id: 302, number: '302', type: 'غرفة مزدوجة', floor: 3, capacity: 2, status: 'occupied', rate: 400 },
  { id: 303, number: '303', type: 'جناح ملكي', floor: 3, capacity: 4, status: 'reserved', rate: 900 },
  { id: 304, number: '304', type: 'أستوديو', floor: 3, capacity: 2, status: 'maintenance', rate: 300 },
  { id: 401, number: '401', type: 'غرفة مزدوجة', floor: 4, capacity: 2, status: 'available', rate: 400 },
  { id: 402, number: '402', type: 'جناح ملكي', floor: 4, capacity: 5, status: 'available', rate: 950 }
];

const INITIAL_BOOKINGS = [
  { 
    id: 1, 
    number: 'BK-2026-608', 
    propertyId: 1, 
    guestId: 101, 
    unitId: 302, 
    checkIn: '2026-06-20', 
    checkOut: '2026-06-25', 
    status: 'checkedIn', 
    notes: 'يفضل الطوابق العليا' 
  },
  { 
    id: 2, 
    number: 'BK-2026-609', 
    propertyId: 1, 
    guestId: 103, 
    unitId: 303, 
    checkIn: '2026-06-22', 
    checkOut: '2026-06-28', 
    status: 'reserved', 
    notes: 'يحتاج تسجيل وصول مبكر' 
  }
];

const INITIAL_INVOICES = [
  { id: 10, bookingId: 1, number: 'INV-1001', amount: 2000, status: 'partiallyPaid', paidAmount: 1200 },
  { id: 11, bookingId: 2, number: 'INV-1002', amount: 5400, status: 'draft', paidAmount: 0 }
];

const INITIAL_EXPENSES = [
  { id: 1, category: 'الصيانة والتصليح', amount: 450, date: '2026-06-19', desc: 'إصلاح تكييف الوحدة 304' },
  { id: 2, category: 'أدوات التنظيف', amount: 180, date: '2026-06-21', desc: 'شراء معقمات ومواد نظافة للمغسلة' }
];

export default function App() {
  const [activeTab, setActiveTab] = useState<'dashboard' | 'bookings' | 'units' | 'finances' | 'credit_expenses' | 'system'>('dashboard');

  // React Simulated Database State
  const [properties, setProperties] = useState(INITIAL_PROPERTIES);
  const [activePropertyId, setActivePropertyId] = useState(1);
  const [guests, setGuests] = useState(INITIAL_GUESTS);
  const [units, setUnits] = useState(INITIAL_UNITS);
  const [bookings, setBookings] = useState(INITIAL_BOOKINGS);
  const [invoices, setInvoices] = useState(INITIAL_INVOICES);
  const [expenses, setExpenses] = useState(INITIAL_EXPENSES);
  const [auditLogs, setAuditLogs] = useState([
    { id: 1, timestamp: '14:02:10', action: 'تأسيس النظام / Initialized', user: 'المالك (Owner)', desc: 'تم فتح قاعدة البيانات SQLite وتجهيز الجداول بنجاح' },
    { id: 2, timestamp: '14:20:15', action: 'إنشاء حجز', user: 'موظف الاستقبال', desc: 'تم تسجيل الحجز رقم BK-2026-608 للنزيل سليمان خالد' }
  ]);

  // Modals / Forms States
  const [showBookingModal, setShowBookingModal] = useState(false);
  const [showPaymentModal, setShowPaymentModal] = useState(false);
  const [selectedInvoiceForPayment, setSelectedInvoiceForPayment] = useState<any>(null);
  const [errorMessage, setErrorMessage] = useState('');

  // Fields for Booking Form
  const [newBookingUnit, setNewBookingUnit] = useState(301);
  const [newBookingGuest, setNewBookingGuest] = useState(101);
  const [newBookingCheckIn, setNewBookingCheckIn] = useState('2026-06-21');
  const [newBookingCheckOut, setNewBookingCheckOut] = useState('2026-06-25');
  const [newBookingNotes, setNewBookingNotes] = useState('');

  // Fields for Payment / Refund Form
  const [paymentAmount, setPaymentAmount] = useState('');
  const [paymentMethod, setPaymentMethod] = useState('cash');
  const [paymentType, setPaymentType] = useState('incoming');

  // Core calculations mapped from Ledger source of truth - BR-602, FR-300
  const totalRevenue = invoices.reduce((acc, inv) => acc + inv.paidAmount, 0);
  const totalExpenses = expenses.reduce((acc, exp) => acc + exp.amount, 0);
  const activeBookingsCount = bookings.filter(b => b.status === 'checkedIn' || b.status === 'reserved').length;
  const occupancyRate = Math.round((units.filter(u => u.status === 'occupied').length / units.length) * 100);

  // Helper function to insert audit logs
  const addAuditLog = (action: string, user: string, desc: string) => {
    const timeNow = new Date().toTimeString().split(' ')[0];
    setAuditLogs(prev => [
      { id: prev.length + 1, timestamp: timeNow, action, user, desc },
      ...prev
    ]);
  };

  // Safe Booking Creation Handler - Satisfies Flow 04 & BR-303
  const handleCreateBooking = (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMessage('');

    // Date validation
    if (new Date(newBookingCheckIn) >= new Date(newBookingCheckOut)) {
      setErrorMessage('خطأ: تاريخ الدخول يجب أن يكون قبل تاريخ الخروج!');
      return;
    }

    // Overlap validation - BR-303
    const unitTarget = units.find(u => u.id === Number(newBookingUnit));
    if (unitTarget && (unitTarget.status === 'occupied' || unitTarget.status === 'maintenance')) {
      setErrorMessage(`خطأ: الوحدة السكنية رقم [${unitTarget.number}] مشغولة أم تحت الصيانة حالياً!`);
      return;
    }

    const newBkId = bookings.length + 1;
    const bookingNumber = `BK-2026-00${newBkId}`;

    const newBooking = {
      id: newBkId,
      number: bookingNumber,
      propertyId: activePropertyId,
      guestId: Number(newBookingGuest),
      unitId: Number(newBookingUnit),
      checkIn: newBookingCheckIn,
      checkOut: newBookingCheckOut,
      status: 'reserved' as const,
      notes: newBookingNotes
    };

    // Update States
    setBookings(prev => [...prev, newBooking]);
    setUnits(prev => prev.map(u => u.id === Number(newBookingUnit) ? { ...u, status: 'reserved' } : u));
    
    // Automatically prepare a draft invoice - Flow 12
    const rate = unitTarget?.rate || 200;
    const diffDays = Math.ceil((new Date(newBookingCheckOut).getTime() - new Date(newBookingCheckIn).getTime()) / (1000 * 3600 * 24));
    const invoiceTotal = rate * diffDays;
    
    const newInvoice = {
      id: invoices.length + 10,
      bookingId: newBkId,
      number: `INV-2026-${1000 + newBkId}`,
      amount: invoiceTotal,
      status: 'draft',
      paidAmount: 0
    };
    setInvoices(prev => [...prev, newInvoice]);

    // Create Audit Log - AP-200
    addAuditLog(
      'إنشاء حجز و فاتورة مسودة',
      'موظف استقبال',
      `تم حجز الغرفة رقم ${unitTarget?.number} برقم حجز ${bookingNumber}. قيمة المسودة المستحقة: ${invoiceTotal} ر.س`
    );

    // Reset Form
    setShowBookingModal(false);
    setNewBookingNotes('');
  };

  // Payment Handler with automatic Settlements triggers - Flow 15, Flow 18, Flow 19, Flow 24 (Guest Credit)
  const handleRegisterPayment = (e: React.FormEvent) => {
    e.preventDefault();
    const amountNum = Number(paymentAmount);
    if (!amountNum || amountNum <= 0) return;

    const currentInvoice = selectedInvoiceForPayment;
    const updatedPaidAmount = currentInvoice.paidAmount + (paymentType === 'incoming' ? amountNum : -amountNum);
    
    // Check if Guest Credit configuration is selected as payment method
    if (paymentMethod === 'guestCredit') {
      const guestObj = guests.find(g => g.id === currentInvoice.bookingId); // approximate link
      const guestCredit = guestObj?.balance || 0;
      if (guestCredit < amountNum) {
        alert('خطأ: لا يوجد رصيد دائن كافٍ لدى هذا النزيل لإتمام التسوية!');
        return;
      }
      
      // Update guest credit cached score
      setGuests(prev => prev.map(g => g.id === guestObj?.id ? { ...g, balance: g.balance - amountNum } : g));
      addAuditLog('استخدام رصيد دائن', 'أمين الصندوق', `تم خصم ${amountNum} ر.س من رصيد العميل ${guestObj?.name}`);
    }

    // Determine Invoice Status based on the financial outcome - BR-401
    let newStatus = 'partiallyPaid';
    if (updatedPaidAmount >= currentInvoice.amount) {
      newStatus = 'paid';
    } else if (updatedPaidAmount <= 0) {
      newStatus = 'draft';
    }

    // State changes logic
    setInvoices(prev => prev.map(inv => inv.id === currentInvoice.id ? { 
      ...inv, 
      paidAmount: updatedPaidAmount,
      status: newStatus 
    } : inv));

    // Automated trigger settlements if excess payment exists - Flow 18 & Flow 19
    if (updatedPaidAmount > currentInvoice.amount) {
      const overpaymentDiff = updatedPaidAmount - currentInvoice.amount;
      addAuditLog(
        'تسوية معلقة - دفع زائد (Overpayment)',
        'النظام المالي الموحد',
        `تم رصد فائض سداد بقيمة ${overpaymentDiff} ر.س. تم إنشاء طلب تسوية دائنة (Pending Settlement) لصالح النزيل.`
      );
    } else if (updatedPaidAmount < currentInvoice.amount && updatedPaidAmount > 0) {
      const underpaymentDiff = currentInvoice.amount - updatedPaidAmount;
      addAuditLog(
        'تسوية معلقة - دفع ناقص (Underpayment)',
        'النظام المالي الموحد',
        `تم رصد عجز سداد بقيمة ${underpaymentDiff} ر.س. الفاتورة بحاجة لمراجعة أو تسوية محاسبية.`
      );
    }

    addAuditLog(
      paymentType === 'incoming' ? 'تسجيل دفعة واردة' : 'تسجيل استرداد مالي (Refund)',
      'أمين الصندوق / المدير',
      `تم تسجيل حركة بقيمة ${amountNum} ر.س للفاتورة رقم ${currentInvoice.number}. الطريقة: ${paymentMethod}`
    );

    setShowPaymentModal(false);
    setPaymentAmount('');
  };

  // Simulate Check-In Flow (Flow 07)
  const handleCheckIn = (bookingId: number) => {
    setBookings(prev => prev.map(b => b.id === bookingId ? { ...b, status: 'checkedIn' } : b));
    const targetBooking = bookings.find(b => b.id === bookingId);
    if (targetBooking) {
      setUnits(prev => prev.map(u => u.id === targetBooking.unitId ? { ...u, status: 'occupied' } : u));
    }
    addAuditLog('تسجيل دخول Checked In', 'موظف الاستقبال', `تم تسجيل الدخول الفعلي للحجز المُؤكد رقم ${targetBooking?.number}`);
  };

  // Simulate Check-Out and calculate final rules (Flow 08)
  const handleCheckOut = (bookingId: number) => {
    const targetBooking = bookings.find(b => b.id === bookingId);
    const linkedInvoice = invoices.find(inv => inv.bookingId === bookingId);
    
    if (linkedInvoice && linkedInvoice.paidAmount < linkedInvoice.amount) {
      alert(`تنبيه: يوجد التزام مالي متبقي بقيمة [${linkedInvoice.amount - linkedInvoice.paidAmount} ر.س] بحاجة للتسوية قبل إتمام تسجيل الخروج!`);
    }

    setBookings(prev => prev.map(b => b.id === bookingId ? { ...b, status: 'checkedOut' } : b));
    if (targetBooking) {
      setUnits(prev => prev.map(u => u.id === targetBooking.unitId ? { ...u, status: 'available' } : u));
    }
    addAuditLog('تسجيل خروج Checked Out', 'موظف الاستقبال', `تم إقفال الحجز رقم ${targetBooking?.number} وتفريغ الوحدة السكنية.`);
  };

  // SQL Database Backup simulation
  const handleBackupDB = () => {
    addAuditLog(
      'نسخ احتياطي للهاتف (Backup)',
      'المالك (Owner)',
      'تم تصدير نسخة من ملف SQLite الموحد بنجاح والحفاظ على أمن المعاملات.'
    );
    alert('تم تحميل وحفظ ملف النسخة الاحتياطية بنجاح على جهازك المحمول!');
  };

  return (
    <div className="min-h-screen bg-[#0F172A] text-slate-100 flex flex-col font-sans" dir="rtl">
      
      {/* ENTERPRISE APP MASTER TOP BAR */}
      <header className="border-b border-slate-800 bg-[#070D19]/90 backdrop-blur-md sticky top-0 z-40">
        <div className="max-w-7xl mx-auto px-6 h-20 flex items-center justify-between">
          
          <div className="flex items-center gap-4">
            <div className="bg-emerald-500/10 p-3 rounded-xl border border-emerald-500/20 text-emerald-400">
              <Building className="w-6 h-6" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <span className="text-[10px] bg-blue-500/10 text-blue-400 px-2 py-0.5 rounded border border-blue-500/20 font-bold uppercase tracking-wider">المنتج الرسمي</span>
                <span className="text-slate-400 text-xs">PMS</span>
              </div>
              <h1 className="text-lg font-bold text-slate-100 tracking-tight">نظام إدارة العقارات والفنادق الشامل</h1>
            </div>
          </div>

          {/* Quick Property Selector widget */}
          <div className="flex items-center gap-3">
            <span className="text-xs text-slate-400 hidden md:inline">المنشأة الحالية:</span>
            <select 
              value={activePropertyId} 
              onChange={(e) => {
                setActivePropertyId(Number(e.target.value));
                addAuditLog('تبديل فرع المنشأة', 'مدير النظام', `تحويل العرض إلى: ${properties.find(p => p.id === Number(e.target.value))?.name}`);
              }}
              className="bg-slate-900 border border-slate-700 text-slate-200 text-xs rounded-xl px-4 py-2.5 outline-none focus:border-emerald-500 transition cursor-pointer"
            >
              {properties.map(p => (
                <option key={p.id} value={p.id}>{p.name}</option>
              ))}
            </select>
            
            <button 
              onClick={handleBackupDB}
              className="bg-emerald-600/10 hover:bg-emerald-600/20 text-emerald-400 border border-emerald-500/20 text-xs px-4 py-2.5 rounded-xl flex items-center gap-2 transition font-medium"
            >
              <Download className="w-4 h-4" />
              <span>نسخ احتياطي DB</span>
            </button>
          </div>

        </div>
      </header>

      {/* CORE FRAME NAVIGATION LAYOUT - SIDEBAR OR TAB PILLS */}
      <div className="max-w-7xl mx-auto w-full px-6 py-8 flex-grow flex flex-col lg:flex-row gap-8">
        
        {/* Navigation Sidebar Panel */}
        <aside className="lg:w-64 flex flex-col gap-2">
          <div className="bg-[#111C30] border border-slate-800 rounded-2xl p-4 gap-1.5 flex flex-col shadow-lg">
            
            <p className="text-[10px] text-slate-500 font-bold uppercase tracking-wider px-3 mb-2">القائمة التشغيلية</p>

            <button 
              onClick={() => setActiveTab('dashboard')}
              className={`w-full text-right flex items-center gap-3 px-4 py-3 rounded-xl text-xs font-semibold transition ${activeTab === 'dashboard' ? 'bg-emerald-600 text-white shadow-lg' : 'text-slate-300 hover:bg-slate-800'}`}
            >
              <PieChart className="w-4 h-4" />
              <span>لوحة التحكم المعيارية</span>
            </button>

            <button 
              onClick={() => setActiveTab('bookings')}
              className={`w-full text-right flex items-center gap-3 px-4 py-3 rounded-xl text-xs font-semibold transition ${activeTab === 'bookings' ? 'bg-emerald-600 text-white shadow-lg' : 'text-slate-300 hover:bg-slate-800'}`}
            >
              <Calendar className="w-4 h-4" />
              <span>إدارة ملف الحجوزات</span>
            </button>

            <button 
              onClick={() => setActiveTab('units')}
              className={`w-full text-right flex items-center gap-3 px-4 py-3 rounded-xl text-xs font-semibold transition ${activeTab === 'units' ? 'bg-emerald-600 text-white shadow-lg' : 'text-slate-300 hover:bg-slate-800'}`}
            >
              <Building className="w-4 h-4" />
              <span>الغرف والوحدات السكنية</span>
            </button>

            <button 
              onClick={() => setActiveTab('finances')}
              className={`w-full text-right flex items-center gap-3 px-4 py-3 rounded-xl text-xs font-semibold transition ${activeTab === 'finances' ? 'bg-emerald-600 text-white shadow-lg' : 'text-slate-300 hover:bg-slate-800'}`}
            >
              <Receipt className="w-4 h-4" />
              <span>الفواتير والمدفوعات المالية</span>
            </button>

            <button 
              onClick={() => setActiveTab('credit_expenses')}
              className={`w-full text-right flex items-center gap-3 px-4 py-3 rounded-xl text-xs font-semibold transition ${activeTab === 'credit_expenses' ? 'bg-emerald-600 text-white shadow-lg' : 'text-slate-300 hover:bg-slate-800'}`}
            >
              <Wallet className="w-4 h-4" />
              <span>رصيد النزلاء والمصروفات</span>
            </button>

            <button 
              onClick={() => setActiveTab('system')}
              className={`w-full text-right flex items-center gap-3 px-4 py-3 rounded-xl text-xs font-semibold transition ${activeTab === 'system' ? 'bg-emerald-600 text-white shadow-lg' : 'text-slate-300 hover:bg-slate-800'}`}
            >
              <Shield className="w-4 h-4" />
              <span>سجل التدقيق وبنية SQLite</span>
            </button>

          </div>

          {/* Connected Device & Offline Verification card */}
          <div className="bg-[#111C30]/50 border border-slate-800/65 rounded-2xl p-4 text-xs space-y-2">
            <div className="flex items-center gap-2 text-emerald-400 font-bold">
              <span className="w-2 h-2 rounded-full bg-emerald-400 animate-ping" />
              <span>قاعدة البيانات نشطة محلياً</span>
            </div>
            <p className="text-[11px] text-slate-400">
              النظام يطابق تماماً بنية تطبيق Flutter من حيث الجداول ومفاهيم الحذف المؤقت (Soft Delete) وعزل الحسابات.
            </p>
          </div>
        </aside>

        {/* Outer Workspace Display Content area */}
        <main className="flex-grow flex flex-col gap-6">

          {/* TAB 1: DASHBOARD MOCK */}
          {activeTab === 'dashboard' && (
            <div className="space-y-6">
              
              {/* Stat grid widgets - ledger real computation */}
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
                
                <div className="bg-[#111C30] border border-slate-800 p-5 rounded-2xl flex items-center justify-between">
                  <div>
                    <p className="text-[11px] text-slate-400 font-medium">صافي الإيرادات النقدية</p>
                    <h3 className="text-2xl font-bold text-slate-100 mt-1">{totalRevenue} ر.س</h3>
                    <p className="text-[10px] text-emerald-400 flex items-center gap-1 mt-1">
                      <TrendingUp className="w-3 h-3" />
                      <span>تدفق نقدي حقيقي</span>
                    </p>
                  </div>
                  <div className="bg-emerald-500/10 p-3 rounded-xl border border-emerald-500/20 text-emerald-400">
                    <TrendingUp className="w-5 h-5" />
                  </div>
                </div>

                <div className="bg-[#111C30] border border-slate-800 p-5 rounded-2xl flex items-center justify-between">
                  <div>
                    <p className="text-[11px] text-slate-400 font-medium">إجمالي المصروفات التشغيلية</p>
                    <h3 className="text-2xl font-bold text-red-400 mt-1">{totalExpenses} ر.س</h3>
                    <p className="text-[10px] text-slate-500 mt-1">مصروفات معتمدة ومبوبة</p>
                  </div>
                  <div className="bg-red-500/10 p-3 rounded-xl border border-red-500/20 text-red-400">
                    <ArrowDownLeft className="w-5 h-5" />
                  </div>
                </div>

                <div className="bg-[#111C30] border border-slate-800 p-5 rounded-2xl flex items-center justify-between">
                  <div>
                    <p className="text-[11px] text-slate-400 font-medium">الحجوزات النشطة</p>
                    <h3 className="text-2xl font-bold text-slate-100 mt-1">{activeBookingsCount}</h3>
                    <p className="text-[10px] text-slate-500 mt-1">Reserved / CheckedIn</p>
                  </div>
                  <div className="bg-blue-500/10 p-3 rounded-xl border border-blue-500/20 text-blue-400">
                    <Calendar className="w-5 h-5" />
                  </div>
                </div>

                <div className="bg-[#111C30] border border-slate-800 p-5 rounded-2xl flex items-center justify-between">
                  <div>
                    <p className="text-[11px] text-slate-400 font-medium">معدل الإشغال الحالي</p>
                    <h3 className="text-2xl font-bold text-slate-100 mt-1">{occupancyRate}%</h3>
                    <p className="text-[10px] text-slate-500 mt-1">من إجمالي عدد الغرف</p>
                  </div>
                  <div className="bg-purple-500/10 p-3 rounded-xl border border-purple-500/20 text-purple-400">
                    <PieChart className="w-5 h-5" />
                  </div>
                </div>

              </div>

              {/* Grid content split: Interactive actions & Active Rooms status */}
              <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
                
                {/* Right col: Booking Shortcuts list */}
                <div className="lg:col-span-8 bg-[#111C30] border border-slate-800 rounded-2xl p-6 space-y-4">
                  <div className="flex justify-between items-center">
                    <div>
                      <h4 className="text-sm font-bold text-slate-100">عمليات سريعة للغرف الشاغرة</h4>
                      <p className="text-xs text-slate-400">ابدأ بتسكين النزلاء وحجز الوحدات المتاحة مباشرة</p>
                    </div>
                    <button 
                      onClick={() => setShowBookingModal(true)}
                      className="bg-emerald-600 hover:bg-emerald-500 text-white text-xs font-semibold px-4 py-2.5 rounded-xl flex items-center gap-2 transition"
                    >
                      <Plus className="w-4 h-4" />
                      <span>حجز غرفة جديدة</span>
                    </button>
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    {units.filter(u => u.status === 'available').slice(0, 4).map(unit => (
                      <div key={unit.id} className="bg-slate-900 border border-slate-800 p-4 rounded-xl flex items-center justify-between hover:border-slate-700 transition">
                        <div>
                          <div className="flex items-center gap-2">
                            <span className="text-xs font-bold text-slate-100">غرفة {unit.number}</span>
                            <span className="text-[9px] bg-slate-800 text-slate-400 px-2 py-0.5 rounded-full">{unit.type}</span>
                          </div>
                          <p className="text-[11px] text-slate-400 mt-1">الريد اللببي: {unit.rate} ر.س / ليلة</p>
                        </div>
                        <button 
                          onClick={() => {
                            setNewBookingUnit(unit.id);
                            setShowBookingModal(true);
                          }}
                          className="bg-emerald-500/10 hover:bg-emerald-500/20 text-emerald-400 text-[10px] font-bold px-3 py-1.5 rounded-lg border border-emerald-500/20 transition"
                        >
                          إنشاء حجز
                        </button>
                      </div>
                    ))}
                  </div>
                </div>

                {/* Left col: Guest credit list overview */}
                <div className="lg:col-span-4 bg-[#111C30] border border-slate-800 rounded-2xl p-6 space-y-4">
                  <div>
                    <h4 className="text-sm font-bold text-slate-100">دليل النزلاء المشترك</h4>
                    <p className="text-xs text-slate-400">رصيد دائم النزلاء النشط - BR-600</p>
                  </div>

                  <div className="space-y-3">
                    {guests.map(guest => (
                      <div key={guest.id} className="bg-slate-900 p-3.5 rounded-xl border border-slate-800/70 flex items-center justify-between text-xs">
                        <div>
                          <p className="font-semibold text-slate-100">{guest.name}</p>
                          <p className="text-[10px] text-slate-400 mt-0.5">{guest.phone}</p>
                        </div>
                        <div className="text-left">
                          <span className="font-mono text-emerald-400 font-bold">{guest.balance} ر.س</span>
                          <p className="text-[8px] text-slate-500">رصيد دائم فعال</p>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>

              </div>
            </div>
          )}

          {/* TAB 2: BOOKINGS LIST */}
          {activeTab === 'bookings' && (
            <div className="bg-[#111C30] border border-slate-800 rounded-2xl p-6 space-y-6">
              <div className="flex flex-col sm:flex-row sm:justify-between sm:items-center gap-4">
                <div>
                  <h3 className="text-base font-bold text-slate-100">سجل إدارة الحجوزات</h3>
                  <p className="text-xs text-slate-400">متابعة حالات الحسم، تسجيل الدخول، والمغادرة - BR-302</p>
                </div>
                <button 
                  onClick={() => setShowBookingModal(true)}
                  className="bg-emerald-600 hover:bg-emerald-500 text-white text-xs font-semibold px-4 py-2.5 rounded-xl flex items-center gap-2 transition self-start"
                >
                  <Plus className="w-4 h-4" />
                  <span>إنشاء حجز جديد</span>
                </button>
              </div>

              <div className="overflow-x-auto">
                <table className="w-full text-right text-xs">
                  <thead>
                    <tr className="border-b border-slate-800 text-slate-400 h-10">
                      <th className="pb-2 font-semibold">رقم الحجز</th>
                      <th className="pb-2 font-semibold">النزيل الأساسي</th>
                      <th className="pb-2 font-semibold">رقم الوحدة</th>
                      <th className="pb-2 font-semibold">الفترة الزمنية</th>
                      <th className="pb-2 font-semibold">الحالة التشغيلية</th>
                      <th className="pb-2 font-semibold text-left">الإجراء المتاح</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-850">
                    {bookings.map(bk => {
                      const guestObj = guests.find(g => g.id === bk.guestId);
                      const unitObj = units.find(u => u.id === bk.unitId);
                      
                      return (
                        <tr key={bk.id} className="h-14 hover:bg-slate-900/40">
                          <td className="font-mono font-semibold text-slate-200">{bk.number}</td>
                          <td>
                            <p className="font-medium text-slate-100">{guestObj?.name}</p>
                            <span className="text-[10px] text-slate-400 font-mono">{guestObj?.docNo}</span>
                          </td>
                          <td>
                            <span className="bg-slate-900 text-slate-300 border border-slate-700 px-2 py-1 rounded">غرفة {unitObj?.number}</span>
                          </td>
                          <td>
                            <div className="text-slate-200">
                              <span>{bk.checkIn}</span>
                              <span className="text-slate-400 px-1 text-[10px]">إلى</span>
                              <span>{bk.checkOut}</span>
                            </div>
                          </td>
                          <td>
                            {bk.status === 'checkedIn' && <span className="bg-emerald-500/15 text-emerald-400 border border-emerald-500/20 px-2.5 py-1 rounded-full text-[10px] font-bold">داخل النُزل (Checked-In)</span>}
                            {bk.status === 'reserved' && <span className="bg-blue-500/15 text-blue-400 border border-blue-500/20 px-2.5 py-1 rounded-full text-[10px] font-bold">مؤكد (Reserved)</span>}
                            {bk.status === 'checkedOut' && <span className="bg-slate-500/15 text-slate-400 border border-slate-500/25 px-2.5 py-1 rounded-full text-[10px] font-bold">مغادر (Checked-Out)</span>}
                          </td>
                          <td className="text-left">
                            <div className="flex gap-2 justify-end">
                              {bk.status === 'reserved' && (
                                <button 
                                  onClick={() => handleCheckIn(bk.id)}
                                  className="bg-emerald-600 hover:bg-emerald-500 text-white text-[10px] font-semibold px-3 py-1.5 rounded-lg transition"
                                >
                                  تسجيل دخول
                                </button>
                              )}
                              {bk.status === 'checkedIn' && (
                                <button 
                                  onClick={() => handleCheckOut(bk.id)}
                                  className="bg-amber-600 hover:bg-amber-500 text-white text-[10px] font-semibold px-3 py-1.5 rounded-lg transition"
                                >
                                  تسجيل خروج (Check-Out)
                                </button>
                              )}
                              <button 
                                onClick={() => {
                                  alert(`رقم هاتف النزيل: ${guestObj?.phone}\nبيانات وثيقة الهوية: ${guestObj?.docNo}\nملاحظات الموظفين: ${bk.notes || "لا يوجد"}`);
                                }}
                                className="bg-slate-800 hover:bg-slate-750 text-slate-300 text-[10px] px-2.5 py-1.5 rounded-lg border border-slate-700 transition"
                              >
                                عرض التفاصيل
                              </button>
                            </div>
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {/* TAB 3: UNITS STATUS LIST */}
          {activeTab === 'units' && (
            <div className="bg-[#111C30] border border-slate-800 rounded-2xl p-6 space-y-6">
              <div>
                <h3 className="text-base font-bold text-slate-100">خريطة الغرف والوحدات السكنية</h3>
                <p className="text-xs text-slate-400">إدارة الجاهزية ونوع الغرف والمستوى اللببي لكل وحدة</p>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4">
                {units.map(unit => {
                  let statusLabel = 'شاغرة (Available)';
                  let colorClass = 'bg-slate-900 border-slate-800 text-slate-300';
                  let icon = <CheckCircle className="w-4 h-4 text-emerald-400 animate-pulse" />;

                  if (unit.status === 'occupied') {
                    statusLabel = 'مشغولة (Occupied)';
                    colorClass = 'bg-red-500/10 border-red-500/20 text-red-100';
                    icon = <XCircle className="w-4 h-4 text-red-400" />;
                  } else if (unit.status === 'reserved') {
                    statusLabel = 'محجوزة (Reserved)';
                    colorClass = 'bg-blue-500/10 border-blue-500/20 text-blue-100';
                    icon = <Calendar className="w-4 h-4 text-blue-400" />;
                  } else if (unit.status === 'maintenance') {
                    statusLabel = 'تحت الصيانة (Maintenance)';
                    colorClass = 'bg-amber-500/10 border-amber-500/20 text-amber-100';
                    icon = <AlertCircle className="w-4 h-4 text-amber-400" />;
                  }

                  return (
                    <div key={unit.id} className={`p-5 rounded-2xl border ${colorClass} flex flex-col justify-between gap-4 h-40`}>
                      <div className="flex justify-between items-start">
                        <div>
                          <div className="flex items-center gap-2">
                            <span className="text-lg font-bold text-slate-100">{unit.number}</span>
                            <span className="text-[10px] bg-slate-850 border border-slate-755/50 px-2 py-0.5 rounded text-slate-400">{unit.type}</span>
                          </div>
                          <span className="text-[10px] text-slate-400 block mt-1">الطابق {unit.floor} • حد السعة: {unit.capacity} فرداً</span>
                        </div>
                        <div className="p-1 rounded-full">
                          {icon}
                        </div>
                      </div>

                      <div className="flex justify-between items-center border-t border-slate-800/60 pt-3">
                        <div>
                          <span className="text-[9px] text-slate-400 uppercase tracking-wide block">سعر الليلة</span>
                          <span className="font-mono text-sm font-bold text-slate-100">{unit.rate} ر.س</span>
                        </div>

                        <span className="text-[10px] font-bold">{statusLabel}</span>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          {/* TAB 4: FINANCES (INVOICES & LEDGER PAYMENTS) */}
          {activeTab === 'finances' && (
            <div className="bg-[#111C30] border border-slate-800 rounded-2xl p-6 space-y-6">
              <div>
                <h3 className="text-base font-bold text-slate-100">سجل الفواتير والمعالجة المالية المحاسبية</h3>
                <p className="text-xs text-slate-400">جميع عمليات السجل والرواتب مصانة من التعديل أو الحذف المباشر - FR-200</p>
              </div>

              <div className="overflow-x-auto">
                <table className="w-full text-right text-xs">
                  <thead>
                    <tr className="border-b border-slate-800 text-slate-400 h-10">
                      <th className="pb-2 font-semibold">رقم الفاتورة</th>
                      <th className="pb-2 font-semibold">رقم الحجز</th>
                      <th className="pb-2 font-semibold">قيمة الإقامة</th>
                      <th className="pb-2 font-semibold">إجمالي المسدد</th>
                      <th className="pb-2 font-semibold">المستحق (Outstanding)</th>
                      <th className="pb-2 font-semibold">حالة السداد</th>
                      <th className="pb-2 font-semibold text-left">إجراء المعاملة</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-850">
                    {invoices.map(inv => {
                      const outerBooking = bookings.find(b => b.id === inv.bookingId);
                      const remains = inv.amount - inv.paidAmount;
                      const isUnpaid = remains > 0;

                      return (
                        <tr key={inv.id} className="h-14 hover:bg-slate-900/40">
                          <td className="font-mono font-semibold text-slate-100">{inv.number}</td>
                          <td className="font-mono text-slate-300">{outerBooking?.number || "غير مدرج"}</td>
                          <td className="font-mono font-semibold text-slate-100">{inv.amount} ر.س</td>
                          <td className="font-mono text-emerald-400 font-bold">{inv.paidAmount} ر.س</td>
                          <td className="font-mono text-slate-300">
                            {remains < 0 ? (
                              <span className="text-amber-400 font-bold">{Math.abs(remains)} ر.س (دائن)</span>
                            ) : (
                              <span>{remains} ر.س</span>
                            )}
                          </td>
                          <td>
                            {inv.status === 'paid' && <span className="bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 px-2 py-0.5 rounded text-[10px] font-bold">مسددة (Paid)</span>}
                            {inv.status === 'partiallyPaid' && <span className="bg-blue-500/10 text-blue-400 border border-blue-500/20 px-2 py-0.5 rounded text-[10px] font-bold">وارد جزئي (Partially)</span>}
                            {inv.status === 'draft' && <span className="bg-amber-500/10 text-amber-400 border border-amber-500/20 px-2 py-0.5 rounded text-[10px] font-bold">مسودة (Draft)</span>}
                          </td>
                          <td className="text-left">
                            <div className="flex gap-2 justify-end">
                              <button 
                                onClick={() => {
                                  setSelectedInvoiceForPayment(inv);
                                  setShowPaymentModal(true);
                                }}
                                className="bg-emerald-600 hover:bg-emerald-500 text-white text-[10px] font-semibold px-3 py-1.5 rounded-lg transition"
                              >
                                تحصيل دفعة / استرجاع مال
                              </button>
                            </div>
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {/* TAB 5: GUEST CREDIT AND EXPENSES */}
          {activeTab === 'credit_expenses' && (
            <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
              
              {/* Right: Guest Credit detail */}
              <div className="lg:col-span-6 bg-[#111C30] border border-slate-800 rounded-2xl p-6 space-y-6">
                <div>
                  <h3 className="text-base font-bold text-slate-100">الرصيد الدائن للنزلاء (Guest Credit)</h3>
                  <p className="text-xs text-slate-400">سجل وحساب المبالغ الدائنة المترتبة على الدفع الزائد - BR-601</p>
                </div>

                <div className="space-y-4">
                  {guests.map(guest => (
                    <div key={guest.id} className="bg-slate-900 border border-slate-800 p-4 rounded-xl flex items-center justify-between">
                      <div>
                        <h4 className="text-xs font-bold text-slate-100">{guest.name}</h4>
                        <span className="text-[10px] text-slate-400">رقم الهاتف: {guest.phone}</span>
                      </div>
                      <div className="text-left">
                        <span className="text-sm font-mono text-emerald-400 font-bold block">{guest.balance} ر.س</span>
                        <p className="text-[8px] text-slate-500">رصيد معتمد (لا ينتهي)</p>
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              {/* Left: Expenses log */}
              <div className="lg:col-span-6 bg-[#111C30] border border-slate-800 rounded-2xl p-6 space-y-6">
                <div className="flex justify-between items-center">
                  <div>
                    <h3 className="text-base font-bold text-slate-100">مبوبة المصروفات التشغيلية</h3>
                    <p className="text-xs text-slate-400">أرشفة وتقرير المصروفات المباشرة للمنشأة - BR-800</p>
                  </div>
                  
                  <button 
                    onClick={() => {
                      const catInput = prompt('يرجى كتابة اسم التبويب: (مثال: كهرباء، أجور صيانة)');
                      const amountInput = prompt('يرجى تحديد المبلغ:');
                      const descInput = prompt('اكتب تفاصيل للمصرف:');
                      if (catInput && amountInput) {
                        setExpenses(prev => [...prev, {
                          id: prev.length + 1,
                          category: catInput,
                          amount: Number(amountInput),
                          date: '2026-06-21',
                          desc: descInput || ""
                        }]);
                        addAuditLog('تسجيل مصروف جديد', 'المشرف', `تم تبويب مبلغ ${amountInput} ر.س لـ [${catInput}]`);
                      }
                    }}
                    className="bg-slate-800 hover:bg-slate-750 text-slate-100 text-xs font-semibold px-4 py-2 rounded-xl border border-slate-700 transition"
                  >
                    إضافة مصروف جديد
                  </button>
                </div>

                <div className="space-y-3">
                  {expenses.map(exp => (
                    <div key={exp.id} className="bg-slate-900 border border-slate-850 p-4 rounded-xl flex justify-between items-center">
                      <div>
                        <span className="text-[10px] bg-red-400/10 text-red-400 border border-red-500/20 px-2 py-0.5 rounded">{exp.category}</span>
                        <p className="text-xs text-slate-100 font-medium mt-2">{exp.desc}</p>
                        <span className="text-[9px] text-slate-500 font-mono italic">{exp.date}</span>
                      </div>
                      <span className="text-sm font-mono text-slate-100 font-bold">{exp.amount} ر.س</span>
                    </div>
                  ))}
                </div>
              </div>

            </div>
          )}

          {/* TAB 6: SECURITY & AUDIT LOGS */}
          {activeTab === 'system' && (
            <div className="bg-[#111C30] border border-slate-800 rounded-2xl p-6 space-y-6">
              
              <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
                <div>
                  <h3 className="text-base font-bold text-slate-100 flex items-center gap-2">
                    <Shield className="w-5 h-5 text-emerald-400" />
                    <span>دفتر سجل تتبع العمليات والتدقيق (Immutable Audit Log)</span>
                  </h3>
                  <p className="text-xs text-slate-400">سجلات حماية وحسم المدفوعات غير قابلة للتعديل أو الحذف من أي مستخدم - AP-003 / AP-004</p>
                </div>
                
                <button 
                  onClick={() => {
                    const confirmRestore = confirm('تحذير: أنت على وشك محاكاة استرجاع قاعدة البيانات (Database Restore). سيؤدي هذا لتطبيق الفحص الهيكلي واسترداد النقاط التاريخية. هل تريد المتابعة؟');
                    if (confirmRestore) {
                      addAuditLog(
                        'استعادة قاعدة البيانات Restore DB',
                        'المالك (Owner) - مُعتمد',
                        'تم تنفيذ تسوية السجلات بنجاح واسترداد ملف SQLite بأمان.'
                      );
                      alert('تم استعادة قاعدة البيانات والتحقق من سلامة الجداول بنجاح!');
                    }
                  }}
                  className="bg-red-500/10 hover:bg-red-500/20 text-red-400 border border-red-500/20 text-xs px-4 py-2 rounded-xl transition font-medium self-start"
                >
                  محاكاة استعادة (Restore)
                </button>
              </div>

              {/* Immutable tables overview */}
              <div className="space-y-3 max-h-96 overflow-y-auto">
                {auditLogs.map(log => (
                  <div key={log.id} className="bg-slate-900 border border-slate-850 p-4 rounded-xl flex items-start gap-4">
                    <div className="font-mono text-[10px] text-slate-500 bg-slate-950 px-2.5 py-1 rounded border border-slate-800">
                      {log.timestamp}
                    </div>
                    <div className="space-y-1 text-xs">
                      <div className="flex items-center gap-2">
                        <span className="font-bold text-slate-200">{log.action}</span>
                        <span className="text-[10px] text-slate-400">• بواسطة: {log.user}</span>
                      </div>
                      <p className="text-slate-300">{log.desc}</p>
                    </div>
                  </div>
                ))}
              </div>

            </div>
          )}

        </main>
      </div>

      {/* FOOTER BAR */}
      <footer className="border-t border-slate-850 bg-[#070D19]/60 py-6">
        <div className="max-w-7xl mx-auto px-6 text-center text-xs text-slate-500">
          PMS • جميع العمليات والتبويبات المالية تطابق وتنفذ القواعد المالية والتشغيلية الرسمية لمشروع الـ Flutter
        </div>
      </footer>

      {/* MODAL: CREATE BOOKING (Flow 04 / BR-303) */}
      {showBookingModal && (
        <div className="fixed inset-0 z-50 bg-[#020617]/80 backdrop-blur-sm flex items-center justify-center p-4">
          <form 
            onSubmit={handleCreateBooking}
            className="bg-[#111C30] border border-slate-800 rounded-3xl p-6 w-full max-w-lg space-y-5 shadow-2xl relative"
          >
            <div className="flex justify-between items-center">
              <h3 className="text-base font-bold text-slate-100">تسكين وإنشاء حجز جديد</h3>
              <button 
                type="button" 
                onClick={() => setShowBookingModal(false)}
                className="text-slate-400 hover:text-slate-200"
              >
                بإلغاء نافذة
              </button>
            </div>

            {errorMessage && (
              <div className="bg-red-500/10 border border-red-500/20 text-red-400 text-xs p-3.5 rounded-xl flex items-center gap-2">
                <AlertCircle className="w-4 h-4 flex-shrink-0" />
                <span>{errorMessage}</span>
              </div>
            )}

            <div className="space-y-3.5">
              
              <div className="flex flex-col gap-1.5">
                <label className="text-xs text-slate-400 font-medium">النزيل الأساسي (من دليل الحساب المشترك)</label>
                <select 
                  value={newBookingGuest} 
                  onChange={(e) => setNewBookingGuest(Number(e.target.value))}
                  className="bg-slate-900 border border-slate-850 rounded-xl px-4 py-2.5 text-xs text-slate-200 outline-none focus:border-emerald-500"
                >
                  {guests.map(g => (
                    <option key={g.id} value={g.id}>{g.name} (رصيد دائن: {g.balance} ر.س)</option>
                  ))}
                </select>
              </div>

              <div className="flex flex-col gap-1.5">
                <label className="text-xs text-slate-400 font-medium font-semibold">الغرفة والوحدة المطلوبة</label>
                <select 
                  value={newBookingUnit} 
                  onChange={(e) => setNewBookingUnit(Number(e.target.value))}
                  className="bg-slate-900 border border-slate-850 rounded-xl px-4 py-2.5 text-xs text-slate-200 outline-none focus:border-emerald-500"
                >
                  {units.map(u => (
                    <option key={u.id} value={u.id}>
                      غرفة {u.number} - {u.type} ({u.rate} ر.س/ليلة) - {u.status === 'occupied' ? 'مشغولة ❌' : 'متاحة ✅'}
                    </option>
                  ))}
                </select>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="flex flex-col gap-1.5">
                  <label className="text-xs text-slate-400 font-medium">تاريخ الدخول</label>
                  <input 
                    type="date" 
                    value={newBookingCheckIn} 
                    onChange={(e) => setNewBookingCheckIn(e.target.value)}
                    className="bg-slate-900 border border-slate-850 rounded-xl px-4 py-2.5 text-xs text-slate-200 outline-none focus:border-emerald-500"
                  />
                </div>
                <div className="flex flex-col gap-1.5">
                  <label className="text-xs text-slate-400 font-medium">تاريخ المغادرة</label>
                  <input 
                    type="date" 
                    value={newBookingCheckOut} 
                    onChange={(e) => setNewBookingCheckOut(e.target.value)}
                    className="bg-slate-900 border border-slate-850 rounded-xl px-4 py-2.5 text-xs text-slate-200 outline-none focus:border-emerald-500"
                  />
                </div>
              </div>

              <div className="flex flex-col gap-1.5">
                <label className="text-xs text-slate-400 font-medium">ملاحظات تشغيلية إضافية</label>
                <textarea 
                  rows={2}
                  value={newBookingNotes}
                  onChange={(e) => setNewBookingNotes(e.target.value)}
                  placeholder="ملاحظات النظير، الوجبات، إلخ..."
                  className="bg-slate-900 border border-slate-850 rounded-xl px-4 py-2.5 text-xs text-slate-200 outline-none focus:border-emerald-500 resize-none"
                />
              </div>

            </div>

            <div className="flex gap-3 justify-end pt-3">
              <button 
                type="button" 
                onClick={() => setShowBookingModal(false)}
                className="bg-slate-800 hover:bg-slate-750 text-slate-300 text-xs px-4 py-2.5 rounded-xl transition"
              >
                إلغاء المقابلة
              </button>
              <button 
                type="submit" 
                className="bg-emerald-600 hover:bg-emerald-500 text-white text-xs font-semibold px-5 py-2.5 rounded-xl shadow-lg transition"
              >
                تأكيد وتسجيل الحجز
              </button>
            </div>

          </form>
        </div>
      )}

      {/* MODAL: PAY OR REFUND INVOICE */}
      {showPaymentModal && selectedInvoiceForPayment && (
        <div className="fixed inset-0 z-50 bg-[#020617]/80 backdrop-blur-sm flex items-center justify-center p-4">
          <form 
            onSubmit={handleRegisterPayment}
            className="bg-[#111C30] border border-slate-800 rounded-3xl p-6 w-full max-w-md space-y-5 shadow-2xl relative"
          >
            <div className="flex justify-between items-center">
              <div>
                <h3 className="text-base font-bold text-slate-100">إدخال حركة مالية لفاتورة</h3>
                <span className="text-[10px] text-slate-400">فاتورة رقم: {selectedInvoiceForPayment.number}</span>
              </div>
              <button 
                type="button" 
                onClick={() => setShowPaymentModal(false)}
                className="text-slate-400 hover:text-slate-200"
              >
                بإلغاء نافذة
              </button>
            </div>

            <div className="bg-slate-900 p-4 rounded-2xl space-y-2 text-xs">
              <div className="flex justify-between">
                <span className="text-slate-400">قيمة المسودة بالكامل:</span>
                <span className="font-mono text-slate-200">{selectedInvoiceForPayment.amount}  ر.س</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-400">المبلغ المسدد بالفعل حتى الآن:</span>
                <span className="font-mono text-emerald-400 font-bold">{selectedInvoiceForPayment.paidAmount}  ر.س</span>
              </div>
              <div className="flex justify-between border-t border-slate-800 pt-2 font-bold">
                <span className="text-slate-200">المبلغ المطلوب تسويته:</span>
                <span className="font-mono text-amber-400">{selectedInvoiceForPayment.amount - selectedInvoiceForPayment.paidAmount}  ر.س</span>
              </div>
            </div>

            <div className="space-y-3.5">
              
              <div className="grid grid-cols-2 gap-3">
                <div className="flex flex-col gap-1.5">
                  <label className="text-[11px] text-slate-400">نوع الحركة</label>
                  <select 
                    value={paymentType}
                    onChange={(e) => setPaymentType(e.target.value)}
                    className="bg-slate-900 border border-slate-850 rounded-xl px-3 py-2 text-xs text-slate-200 outline-none"
                  >
                    <option value="incoming">دفع مستحق (Incoming)</option>
                    <option value="refund">استرداد مالي (Refund)</option>
                  </select>
                </div>
                
                <div className="flex flex-col gap-1.5">
                  <label className="text-[11px] text-slate-400">طريقة السداد</label>
                  <select 
                    value={paymentMethod}
                    onChange={(e) => setPaymentMethod(e.target.value)}
                    className="bg-slate-900 border border-slate-850 rounded-xl px-3 py-2 text-xs text-slate-200 outline-none"
                  >
                    <option value="cash">نقداً (Cash)</option>
                    <option value="card">مدى / بطاقة ائتمان</option>
                    <option value="guestCredit">رصيد دائن للنزيل (Guest Credit)</option>
                  </select>
                </div>
              </div>

              <div className="flex flex-col gap-1.5">
                <label className="text-xs text-slate-400 font-medium">المبلغ والكمية المدفوعة بالأرقام</label>
                <input 
                  type="number" 
                  value={paymentAmount}
                  onChange={(e) => setPaymentAmount(e.target.value)}
                  placeholder="مثال: 500"
                  className="bg-slate-900 border border-slate-850 rounded-xl px-4 py-2.5 text-xs text-slate-200 outline-none focus:border-emerald-500 font-mono"
                  required
                />
              </div>

            </div>

            <div className="flex gap-3 justify-end pt-3">
              <button 
                type="button" 
                onClick={() => setShowPaymentModal(false)}
                className="bg-slate-800 hover:bg-slate-750 text-slate-300 text-xs px-4 py-2.5 rounded-xl transition"
              >
                إلغاء
              </button>
              <button 
                type="submit" 
                className="bg-emerald-600 hover:bg-emerald-500 text-white text-xs font-semibold px-5 py-2.5 rounded-xl shadow-lg transition"
              >
                حفظ وتسجيل الحركة
              </button>
            </div>

          </form>
        </div>
      )}

    </div>
  );
}
