import Rails from "@rails/ujs"
Rails.start()

// 年度別ランキングの折りたたみ: デスクトップ幅では初期状態で展開する
document.addEventListener("DOMContentLoaded", () => {
  if (!window.matchMedia("(min-width: 992px)").matches) return

  document.querySelectorAll(".year-collapse").forEach((collapse) => {
    collapse.classList.add("show")
    const toggle = document.querySelector(`.year-toggle[data-bs-target="#${collapse.id}"]`)
    if (toggle) toggle.setAttribute("aria-expanded", "true")
  })
})
