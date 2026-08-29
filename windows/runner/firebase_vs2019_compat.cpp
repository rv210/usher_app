#include <windows.h>
#include <cstdint>
#include <cstring>
#include <algorithm>

extern "C" {

const void* __std_find_trivial_8(const void* first, const void* last, uint64_t val) {
    const uint64_t* f = static_cast<const uint64_t*>(first);
    const uint64_t* l = static_cast<const uint64_t*>(last);
    while (f < l) {
        if (*f == val) return f;
        ++f;
    }
    return l;
}

const void* __std_find_trivial_2(const void* first, const void* last, uint16_t val) {
    const uint16_t* f = static_cast<const uint16_t*>(first);
    const uint16_t* l = static_cast<const uint16_t*>(last);
    while (f < l) {
        if (*f == val) return f;
        ++f;
    }
    return l;
}

const void* __std_find_trivial_1(const void* first, const void* last, uint8_t val) {
    const uint8_t* f = static_cast<const uint8_t*>(first);
    const uint8_t* l = static_cast<const uint8_t*>(last);
    while (f < l) {
        if (*f == val) return f;
        ++f;
    }
    return l;
}

const void* __std_find_last_trivial_1(const void* first, const void* last, uint8_t val) {
    const uint8_t* f = static_cast<const uint8_t*>(first);
    const uint8_t* l = static_cast<const uint8_t*>(last);
    while (l > f) {
        --l;
        if (*l == val) return l;
    }
    return static_cast<const uint8_t*>(last);
}

const void* __std_min_element_8(const void* first, const void* last) {
    const int64_t* f = static_cast<const int64_t*>(first);
    const int64_t* l = static_cast<const int64_t*>(last);
    if (f >= l) return first;
    const int64_t* min_ptr = f;
    while (++f < l) {
        if (*f < *min_ptr) min_ptr = f;
    }
    return min_ptr;
}

int64_t __std_min_8i(const void* first, const void* last) {
    const int64_t* res = static_cast<const int64_t*>(__std_min_element_8(first, last));
    return res ? *res : 0;
}

void __std_init_once_link_alternate_names_and_abort() {
    // No-op
}

const void* __std_search_1(const void* first1, const void* last1, const void* first2, const void* last2) {
    const uint8_t* f1 = static_cast<const uint8_t*>(first1);
    const uint8_t* l1 = static_cast<const uint8_t*>(last1);
    const uint8_t* f2 = static_cast<const uint8_t*>(first2);
    const uint8_t* l2 = static_cast<const uint8_t*>(last2);
    size_t len1 = l1 - f1;
    size_t len2 = l2 - f2;
    if (len2 == 0) return first1;
    if (len1 < len2) return last1;
    for (size_t i = 0; i <= len1 - len2; ++i) {
        if (std::memcmp(f1 + i, f2, len2) == 0) {
            return f1 + i;
        }
    }
    return last1;
}

const void* __std_find_end_1(const void* first1, const void* last1, const void* first2, const void* last2) {
    const uint8_t* f1 = static_cast<const uint8_t*>(first1);
    const uint8_t* l1 = static_cast<const uint8_t*>(last1);
    const uint8_t* f2 = static_cast<const uint8_t*>(first2);
    const uint8_t* l2 = static_cast<const uint8_t*>(last2);
    size_t len1 = l1 - f1;
    size_t len2 = l2 - f2;
    if (len2 == 0) return last1;
    if (len1 < len2) return last1;
    for (size_t i = len1 - len2 + 1; i > 0; --i) {
        size_t idx = i - 1;
        if (std::memcmp(f1 + idx, f2, len2) == 0) {
            return f1 + idx;
        }
    }
    return last1;
}

const void* __std_find_first_of_trivial_1(const void* first1, const void* last1, const void* first2, const void* last2) {
    const uint8_t* f1 = static_cast<const uint8_t*>(first1);
    const uint8_t* l1 = static_cast<const uint8_t*>(last1);
    const uint8_t* f2 = static_cast<const uint8_t*>(first2);
    const uint8_t* l2 = static_cast<const uint8_t*>(last2);
    while (f1 < l1) {
        for (const uint8_t* p = f2; p < l2; ++p) {
            if (*f1 == *p) return f1;
        }
        ++f1;
    }
    return l1;
}

void* __std_remove_8(void* first, void* last, uint64_t val) {
    uint64_t* f = static_cast<uint64_t*>(first);
    uint64_t* l = static_cast<uint64_t*>(last);
    uint64_t* result = f;
    while (f < l) {
        if (*f != val) {
            *result = *f;
            ++result;
        }
        ++f;
    }
    return result;
}

size_t __std_find_last_of_trivial_pos_1(const void* str, size_t pos, const void* targets, size_t targets_len) {
    const uint8_t* s = static_cast<const uint8_t*>(str);
    const uint8_t* t = static_cast<const uint8_t*>(targets);
    if (pos == static_cast<size_t>(-1)) return static_cast<size_t>(-1);
    for (size_t i = pos + 1; i > 0; --i) {
        size_t idx = i - 1;
        for (size_t j = 0; j < targets_len; ++j) {
            if (s[idx] == t[j]) return idx;
        }
    }
    return static_cast<size_t>(-1);
}

void _Thrd_sleep_for(int64_t duration_ms) {
    Sleep(static_cast<DWORD>(duration_ms > 0 ? duration_ms : 0));
}

int _Cnd_timedwait_for_unchecked(void* cnd, void* mtx, const void* duration) {
    return 0;
}

int _Cnd_timedwait_for(void* cnd, void* mtx, const void* duration) {
    return 0;
}

} // extern "C"
