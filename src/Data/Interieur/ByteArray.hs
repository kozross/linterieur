{-# LANGUAGE MagicHash #-}
{-# LANGUAGE UnliftedFFITypes #-}

-- |
-- Module: Data.ByteArray.Interieur
-- Copyright: (C) 2021 Koz Ross
-- License: Apache 2.0
-- Maintainer: Koz Ross <koz.ross@retro-freedom.nz>
-- Stability: stable
-- Portability: GHC only
--
-- Several functions working with 'ByteArray's and 'ByteArray#'s.
--
-- = Important note
--
-- No bounds checking (or indeed, checking of any prerequisites) is done by any
-- of these functions. Use with care.
module Data.Interieur.ByteArray
  ( -- * Wrapped operations
    findFirstByte,
    findFirstByteIn,
    findLastByte,
    findLastByteIn,
    countBytesEq,
    countBytesEqIn,

    -- * Raw operations
    findFirstByte#,
    findFirstByteIn#,
    findLastByte#,
    findLastByteIn#,
    countBytesEq#,
    countBytesEqIn#,
  )
where

import Data.Primitive.ByteArray
  ( ByteArray (ByteArray),
    sizeofByteArray,
  )
import Foreign.C.Types (CInt (CInt), CPtrdiff (CPtrdiff))
import GHC.Exts
  ( ByteArray#,
    Int (I#),
    Int#,
    sizeofByteArray#,
    word2Int#,
  )
import GHC.Word (Word8 (W8#))

-- Wrapped ops

-- | A convenience wrapper for searching the entire 'ByteArray'. More precisely,
-- @findFirstByte ba w8@ is the same as @'findFirstByteIn' ba 0 ('sizeofByteArray'
-- ba) w8@.
--
-- @since 1.0.0
findFirstByte :: ByteArray -> Word8 -> Maybe Int
findFirstByte ba = findFirstByteIn ba 0 (sizeofByteArray ba)

-- | Identical to 'findFirstByteIn#', except using lifted types, and using a
-- 'Maybe' argument for the result to avoid negative-number indices.
--
-- = Prerequisites
--
-- Let @off@ be the offset argument, @len@ be the length
-- argument, @ba@ the 'ByteArray' argument, and @w8@ the byte to match.
--
-- * @0 '<=' off@ and @off '<' 'sizeofByteArray' ba@
-- * @0 '<=' len@ and @len + off <= 'sizeofByteArray' ba@
--
-- = Outcomes
--
-- Let @res@ be the result of a call @findFirstByteIn ba off len w8@.
--
-- * If @w8@ exists in the index range @off .. off + len - 1@, then @res@ will
--   be in a 'Just' with a value in the range @off .. off + len - 1@
-- * Otherwise, @res = 'Nothing'@.
--
-- @since 1.0.0
findFirstByteIn :: ByteArray -> Int -> Int -> Word8 -> Maybe Int
findFirstByteIn (ByteArray ba#) (I# off#) (I# len#) (W8# w8#) =
  let (CPtrdiff res) = findFirstByteIn# ba# off# len# (word2Int# w8#)
   in case signum res of
        (-1) -> Nothing
        _ -> Just . fromIntegral $ res

-- | A convenience wrapper for searching the entire 'ByteArray'. More precisely,
-- @findLastByte ba w8@ is the same as @'findLastByteIn' ba 0 ('sizeofByteArray'
-- ba) w8@.
--
-- @since 1.0.0
findLastByte :: ByteArray -> Word8 -> Maybe Int
findLastByte ba = findLastByteIn ba 0 (sizeofByteArray ba)

-- | A convenience wrapper for counting the entire 'ByteArray'. More precisely,
-- @countBytesEq ba w8@ is the same as @'countBytesEqIn' ba 0 ('sizeofByteArray' ba)
-- w8@.
--
-- @since 1.0.0
countBytesEq :: ByteArray -> Word8 -> Int
countBytesEq ba = countBytesEqIn ba 0 (sizeofByteArray ba)

-- | Identical to 'findLastByteIn#', except using lifted types, and using a
-- 'Maybe' argument for the result to avoid negative-number indices.
--
-- = Prerequisites
--
-- Let @off@ be the offset argument, @len@ be the length
-- argument, @ba@ the 'ByteArray' argument, and @w8@ the byte to match.
--
-- * @0 '<=' off@ and @off '<' 'sizeofByteArray' ba@
-- * @0 '<=' len@ and @len + off <= 'sizeofByteArray' ba@
--
-- = Outcomes
--
-- Let @res@ be the result of a call @findFirstByteIn ba off len w8@.
--
-- * If @w8@ exists in the index range @off .. off + len - 1@, then @res@ will
--   be in a 'Just' with a value in the range @off .. off + len - 1@
-- * Otherwise, @res = 'Nothing'@.
--
-- @since 1.0.0
findLastByteIn :: ByteArray -> Int -> Int -> Word8 -> Maybe Int
findLastByteIn (ByteArray ba#) (I# off#) (I# len#) (W8# w8#) =
  let (CPtrdiff res) = findLastByteIn# ba# off# len# (word2Int# w8#)
   in case signum res of
        (-1) -> Nothing
        _ -> Just . fromIntegral $ res

-- | Identical to 'countBytesEqIn#', except using lifted types.
--
-- = Prerequisites
--
-- Let @off@ be the offset argument, @len@ be the length argument, @ba@ the
-- 'ByteArray' argument, and @w8@ the byte to count.
--
-- * @0 '<=' off@ and @off '<' 'sizeofByteArray' ba@
-- * @0 '<=' len@ and @len + off <= 'sizeofByteArray' ba@
--
-- = Outcomes
--
-- Let @res@ be the result of a call @countBytesEqIn ba off len w8@.
--
-- * @0 '<=' res@ and @res '<' len@.
--
-- @since 1.0.0
countBytesEqIn :: ByteArray -> Int -> Int -> Word8 -> Int
countBytesEqIn (ByteArray ba#) (I# off#) (I# len#) (W8# w8#) =
  let (CInt res) = countBytesEqIn# ba# off# len# (word2Int# w8#)
   in fromIntegral res

-- Raw ops

-- | A convenience wrapper for searching the entire 'ByteArray#'. More
-- precisely, @findFirstByte# ba w8#@ is the same as @'findFirstByteIn#' ba 0#
-- ('sizeofByteArray#' ba) w8@.
--
-- @since 1.0.0
findFirstByte# :: ByteArray# -> Int# -> CPtrdiff
findFirstByte# ba# = findFirstByteIn# ba# 0# (sizeofByteArray# ba#)

-- | A convenience wrapper for searching the entire 'ByteArray#'. More
-- precisely, @findLastByte# ba w8@ is the same as @'findLastByteIn#' ba 0#
-- ('sizeofByteArray#' ba) w8@.
--
-- @since 1.0.0
findLastByte# :: ByteArray# -> Int# -> CPtrdiff
findLastByte# ba# = findLastByteIn# ba# 0# (sizeofByteArray# ba#)

-- | A convenience wrapper for counting in the entire 'ByteArray#'. More
-- precisely, @countBytesEq# ba w8@ is the same as @'countBytesEqIn#' ba 0#
-- ('sizeofByteArray#' ba) w8@.
--
-- @since 1.0.0
countBytesEq# :: ByteArray# -> Int# -> CInt
countBytesEq# ba# = countBytesEqIn# ba# 0# (sizeofByteArray# ba#)

-- | Searches a byte array from an offset for the index of the
-- first occurrence of a byte.
--
-- = Prerequisites
--
-- Let @off@ be the offset argument, @len@ be the length
-- argument, @ba@ the 'ByteArray#' argument, and @w8@ the byte to match.
--
-- * @0 '<=' off@ and @off '<' 'sizeofByteArray#' ba@
-- * @0 '<=' len@ and @len + off <= 'sizeofByteArray#' ba@
-- * @0 '<=' w8@ and @w8 '<' 255@
--
-- = Outcomes
--
-- Let @res@ be the result of a call @findFirstByteIn# ba off len w8@.
--
-- * If @w8@ exists in the index range @off .. off + len - 1@, then @res@ will
--   be in the range @off .. off + len - 1@
-- * Otherwise, @res = -1@
--
-- = Notes
--
-- This calls @[memchr](https://man7.org/linux/man-pages/man3/memchr.3.html)@ underneath.
--
-- @since 1.0.0
foreign import ccall unsafe "find_first_byte"
  findFirstByteIn# ::
    -- | The memory area to search
    ByteArray# ->
    -- | Offset from the start
    Int# ->
    -- | How many bytes to check
    Int# ->
    -- | What byte to match (only low 8 bits)
    Int# ->
    -- | Location as index, or -1 if not found
    CPtrdiff

-- | Searches a byte array from an offset for the index of the
-- last occurrence of a byte.
--
-- = Prerequisites
--
-- Let @off@ be the offset argument, @len@ be the length
-- argument, @ba@ the 'ByteArray#' argument, and @w8@ the byte to match.
--
-- * @0 '<=' off@ and @off '<' 'sizeofByteArray#' ba@
-- * @0 '<=' len@ and @len + off <= 'sizeofByteArray#' ba@
-- * @0 '<=' w8@ and @w8 '<' 255@
--
-- = Outcomes
--
-- Let @res@ be the result of a call @findFirstByteIn# ba off len w8@.
--
-- * If @w8@ exists in the index range @off .. off + len - 1@, then @res@ will
--   be in the range @off .. off + len - 1@
-- * Otherwise, @res = -1@
--
-- = Notes
--
-- This calls @[memrchr](https://linux.die.net/man/3/memrchr)@ underneath. While
-- this is not mandated by any C standard, implementations exist for Glibc,
-- musl, and both the FreeBSD and OpenBSD libc. On MacOS, we provide an
-- implementation in portable C.
--
-- @since 1.0.0
foreign import ccall unsafe "find_last_byte"
  findLastByteIn# ::
    -- | The memory area to search
    ByteArray# ->
    -- | Offset from the start
    Int# ->
    -- | How many bytes to check
    Int# ->
    -- | What byte to match (only low 8 bits)
    Int# ->
    -- | Location as index, or -1 if not found
    CPtrdiff

-- | Counts the occurrences of a specific byte in a byte array from an offset.
--
-- = Prerequisites
--
-- Let @off@ be the offset argument, @len@ be the length argument, @ba@ the
-- 'ByteArray#' argument, and @w8@ the byte to count.
--
-- * @0 '<=' off@ and @off '<' 'sizeofByteArray#' ba@
-- * @0 '<=' len@ and @len + off <= 'sizeofByteArray#' ba@
-- * @0 '<=' w8@ and @w8 '<' 255@
--
-- = Outcomes
--
-- Let @res@ be the result of a call @countBytesEqIn# ba off len w8@.
--
-- * @0 '<=' res@ and @res '<' len@.
--
-- @since 1.0.0
foreign import ccall unsafe "count_bytes_eq"
  countBytesEqIn# ::
    -- | The memory area to count
    ByteArray# ->
    -- | Offset from the start
    Int# ->
    -- | How many bytes to check
    Int# ->
    -- | What byte to count (only low 8 bits)
    Int# ->
    -- | How many times the byte occurs
    CInt
