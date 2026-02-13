/**
 * Scroll Animations and Mobile Menu
 * Handles scroll-triggered animations and responsive mobile menu
 */

// Initialize scroll animations
function initScrollAnimations() {
  const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -50px 0px'
  };

  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.classList.add('active');
        observer.unobserve(entry.target);
      }
    });
  }, observerOptions);

  // Apply observer to all scroll-animate elements
  document.querySelectorAll('.scroll-animate, .scroll-animate-scale, .scroll-animate-left, .scroll-animate-right, .scroll-animate-fly-left, .scroll-animate-fly-right, .scroll-animate-rotate, .scroll-animate-bounce').forEach(el => {
    observer.observe(el);
  });
}

// Scroll to top button functionality
function initScrollToTop() {
  const scrollBtn = document.getElementById('scrollToTopBtn');
  if (!scrollBtn) return;

  // Show/hide button based on scroll position
  window.addEventListener('scroll', () => {
    if (window.pageYOffset > 300) {
      scrollBtn.classList.add('visible');
    } else {
      scrollBtn.classList.remove('visible');
    }
  });

  // Scroll to top when clicked
  scrollBtn.addEventListener('click', () => {
    window.scrollTo({
      top: 0,
      behavior: 'smooth'
    });
  });
}


// Add auto scroll animations to common elements
function autoApplyScrollAnimations() {
  // Define animation types to rotate through
  const animations = ['scroll-animate-fly-left', 'scroll-animate-fly-right', 'scroll-animate-bounce', 'scroll-animate-rotate', 'scroll-animate-scale'];
  
  // Apply to cards with varied animations
  document.querySelectorAll('.card').forEach((el, index) => {
    if (!el.classList.contains('scroll-animate') && !el.classList.contains('scroll-animate-fly-left')) {
      const animClass = animations[index % animations.length];
      el.classList.add(animClass);
      el.style.transitionDelay = (index * 0.03) + 's';
    }
  });

  // Apply to school cards with alternating side animations
  document.querySelectorAll('.school-card').forEach((el, index) => {
    if (!el.classList.contains('scroll-animate') && !el.classList.contains('scroll-animate-fly-left')) {
      const animClass = index % 2 === 0 ? 'scroll-animate-fly-left' : 'scroll-animate-fly-right';
      el.classList.add(animClass);
      el.style.transitionDelay = (index * 0.03) + 's';
    }
  });

  // Apply to finalist cards with bounce
  document.querySelectorAll('.finalist-card').forEach((el, index) => {
    if (!el.classList.contains('scroll-animate')) {
      el.classList.add('scroll-animate-bounce');
      el.style.transitionDelay = (index * 0.03) + 's';
    }
  });

  // Apply to table rows with alternating
  document.querySelectorAll('table tbody tr').forEach((el, index) => {
    if (!el.classList.contains('scroll-animate')) {
      const animClass = index % 2 === 0 ? 'scroll-animate-left' : 'scroll-animate-right';
      el.classList.add(animClass);
      el.style.transitionDelay = (index * 0.02) + 's';
    }
  });

  // Apply to sections
  document.querySelectorAll('section').forEach((el, index) => {
    if (!el.classList.contains('scroll-animate')) {
      el.classList.add('scroll-animate');
      el.style.transitionDelay = (index * 0.03) + 's';
    }
  });

  // Apply to illustration cards with rotation
  document.querySelectorAll('.illustration-card').forEach((el, index) => {
    if (!el.classList.contains('scroll-animate')) {
      el.classList.add('scroll-animate-rotate');
      el.style.transitionDelay = (index * 0.03) + 's';
    }
  });
}

// Initialize all functionality
function initScrollFeaturesOnReady() {
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
      autoApplyScrollAnimations();
      initScrollAnimations();
      initScrollToTop();
    });
  } else {
    autoApplyScrollAnimations();
    initScrollAnimations();
    initScrollToTop();
  }
}

// Start initialization
initScrollFeaturesOnReady();

// Re-apply animations to dynamically added content
const mutationObserver = new MutationObserver(() => {
  const newElements = document.querySelectorAll('.card:not(.scroll-animate-fly-left):not(.scroll-animate-fly-right), .school-card:not(.scroll-animate-fly-left), .finalist-card:not(.scroll-animate-bounce)');
  if (newElements.length > 0) {
    autoApplyScrollAnimations();
    initScrollAnimations();
  }
});

mutationObserver.observe(document.body, { childList: true, subtree: true });
